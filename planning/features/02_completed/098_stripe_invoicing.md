# Feature — Stripe Invoicing (Admin Send Invoice)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Low | **Complexity:** Low
**Flag:** `STRIPE_INVOICING_ENABLED=true` (dart-define in client.json)
**Note:** Implement this before `094_invoice_generation.md`. May be sufficient without custom PDF generation.

---

## Objective

A "Send Invoice" button in admin that calls the Stripe Invoices API to create and email a
Stripe-hosted invoice to the client. Stripe handles the PDF, payment link, and tracking.

---

## What's Already in Place

- `booking_overview_view.dart` — at `lib/modules/admin/views/master/booking_overview_view.dart`
  (confirmed path). Currently **298 lines**. Adding a "Send Invoice" button will push it over 300.
  The `_BookingTile` class (lines 124–241, ~117 lines) must be extracted to
  `lib/modules/admin/views/master/booking_tile.dart` first. Required prerequisite.
- `stripe-dispatcher/index.ts` — `STRIPE_SK` set as manual Supabase secret for all Stripe clients.
  `send-stripe-invoice` reuses it. Note: `deliver.sh` does NOT auto-push `STRIPE_SK` — it's a
  manual step noted in the checklist. No new secrets beyond existing Stripe setup.
- `MasterController` (`lib/modules/admin/controllers/master_controller.dart`, 254 lines) —
  correct location for `sendStripeInvoice()`. Uses `SupabaseService.client.functions.invoke()`.
- JWT verification pattern (from `connect-stripe-onboard`) — use `SUPABASE_ANON_KEY` + forwarded
  `Authorization` header to resolve the calling user, then verify role with service-role client.

---

## Schema Changes

**Migration: `094_stripe_invoicing.sql`** (next after 093_sms_reminder_sent.sql)

```sql
ALTER TABLE bookings ADD COLUMN stripe_invoice_id  text;
ALTER TABLE bookings ADD COLUMN stripe_invoice_url  text;
ALTER TABLE bookings ADD COLUMN invoice_sent_at     timestamptz;
```

Note: if `094_invoice_generation.md` (PDF invoices) is implemented alongside this,
`invoice_sent_at` is shared — consolidate into one migration at that point.

---

## Edge Function

**`send-stripe-invoice/index.ts`** — requires master JWT.

```ts
import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'
```

Flow:
1. **JWT verification** — same pattern as `connect-stripe-onboard`:
   ```ts
   const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
     global: { headers: { Authorization: authHeader } },
   })
   const { data: { user } } = await anonClient.auth.getUser()
   if (!user) return json({ error: 'Unauthorized' }, 401)
   ```
2. **Role check** — query `profiles` with service-role client:
   ```ts
   const { data: profile } = await db.from('profiles')
     .select('role').eq('user_id', user.id).single()
   if (profile?.role !== 'master') return json({ error: 'Forbidden' }, 403)
   ```
3. **Load booking** — must be `status = 'confirmed'`, return 400 otherwise.
4. **Create/retrieve Stripe Customer**:
   ```ts
   const customers = await stripe.customers.list({ email: booking.client_email, limit: 1 })
   const customer = customers.data[0] ??
     await stripe.customers.create({ email: booking.client_email, name: booking.client_name })
   ```
5. **Create Invoice + line item + finalize + send**:
   ```ts
   const invoice = await stripe.invoices.create({ customer: customer.id, auto_advance: false })
   await stripe.invoiceItems.create({
     customer:    customer.id,
     invoice:     invoice.id,
     description: (booking.service_names as string[]).join(', '),
     amount:      Math.round(Number(booking.total_price) * 100), // Number() — DB returns string
     currency:    'usd',
   })
   const finalized = await stripe.invoices.finalizeInvoice(invoice.id)
   await stripe.invoices.sendInvoice(invoice.id)
   ```
   Note: `Number(booking.total_price)` required — Supabase JS returns `numeric` columns as strings.
6. **Store on booking row**:
   ```ts
   await db.from('bookings').update({
     stripe_invoice_id:  finalized.id,
     stripe_invoice_url: finalized.hosted_invoice_url,
     invoice_sent_at:    new Date().toISOString(),
   }).eq('id', booking_id)
   ```
7. Return `{ invoice_url: finalized.hosted_invoice_url }`.

---

## Flutter Changes

### `app_env.dart`
```dart
static const stripeInvoicingEnabled = bool.fromEnvironment(
  'STRIPE_INVOICING_ENABLED',
  defaultValue: false,
);
```

### Extract `booking_tile.dart` (prerequisite)

Move `_BookingTile` from `booking_overview_view.dart` (lines ~124–241) to
`lib/modules/admin/views/master/booking_tile.dart` as public `BookingTile`.
After extraction `booking_overview_view.dart` drops to ~180 lines.

Add invoice button inside `BookingTile` build method:
```dart
if (AppEnv.stripeInvoicingEnabled && booking.status == 'confirmed') ...[
  TextButton(
    onPressed: () => controller.sendStripeInvoice(booking.id),
    child: Text(
      booking.stripeInvoiceId != null ? 'RESEND INVOICE' : 'SEND INVOICE',
      style: ETextStyles.labelSm,
    ),
  ),
]
```

### `BookingModel` — add 3 nullable fields

```dart
final String? stripeInvoiceId;
final String? stripeInvoiceUrl;
final DateTime? invoiceSentAt;
```

`fromJson` mappings:
```dart
stripeInvoiceId:  json['stripe_invoice_id']  as String?,
stripeInvoiceUrl: json['stripe_invoice_url'] as String?,
invoiceSentAt:    json['invoice_sent_at'] != null
    ? DateTime.parse(json['invoice_sent_at'] as String)
    : null,
```

### `MasterController` — add `sendStripeInvoice()`

```dart
Future<void> sendStripeInvoice(String bookingId) async {
  try {
    final res = await SupabaseService.client.functions.invoke(
      'send-stripe-invoice',
      body: {'booking_id': bookingId},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data?['error'] != null) {
      Get.snackbar('Error', data!['error'].toString());
      return;
    }
    final url = data?['invoice_url'] as String?;
    Get.snackbar('Invoice sent', url ?? 'Invoice emailed to client');
    await loadBookings(); // refresh list so RESEND appears
  } catch (e) {
    Get.snackbar('Error', 'Could not send invoice');
  }
}
```

---

## client.json / deliver.sh

```json
"STRIPE_INVOICING_ENABLED": "true"
```

`deliver.sh`: deploy `send-stripe-invoice` when `STRIPE_INVOICING_ENABLED=true`.
Add checklist reminder that `STRIPE_SK` must be set as a Supabase secret before invoices work
(same manual step already noted for other Stripe features).

---

## Acceptance Criteria

- [ ] `STRIPE_INVOICING_ENABLED=false` — no button, no function deployed
- [ ] "SEND INVOICE" button visible on confirmed booking tiles
- [ ] "RESEND INVOICE" shown after first send (`stripeInvoiceId` non-null)
- [ ] Stripe invoice created, finalised, and emailed to client's email address
- [ ] `stripe_invoice_id` + `stripe_invoice_url` + `invoice_sent_at` stored on booking row
- [ ] Admin tile refreshes to show RESEND state after send
- [ ] Non-master JWT returns 403; unauthenticated returns 401
- [ ] Non-confirmed booking returns 400
- [ ] `booking_overview_view.dart` ≤ 300 lines after tile extraction
- [ ] All files ≤ 300 lines
