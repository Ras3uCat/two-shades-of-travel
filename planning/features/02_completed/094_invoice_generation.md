# Feature — Invoice Generation (PDF via Resend)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (3rd pass) | **Mode:** STUDIO | **Status:** COMPLETE
**Priority:** Medium | **Complexity:** Medium
**Flag:** `INVOICES_ENABLED=true` (dart-define in client.json)
**Note:** Implement `098_stripe_invoicing.md` first — it may be sufficient without this. Confirmed complete.

---

## Objective

After a booking is paid, automatically email a branded PDF invoice via Resend. Targeted at the
corporate personality — law firms, medical, B2B where clients need invoices for expense reporting.

---

## What's Already in Place

- `stripe-dispatcher/_handlers/booking.ts` — `handleBookingConfirmation()` is where the invoice
  trigger goes (fires after payment confirmed). Internal calls use direct `fetch()` with
  `Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}` — same pattern as `send-notification` and
  `process-referral` calls at lines 150–166. Do NOT use `supabase.functions.invoke()` here.
- `send-notification/index.ts` — Resend email sender. Invoice uses Resend's `attachments` API
  (base64 PDF). Call Resend directly from `generate-invoice` (not via send-notification).
- `business_config` — has `logo_url text` (defined in `000_base.sql`). No schema change needed
  for the logo. Must be a public Supabase Storage URL (not signed — signed URLs expire and
  will break PDFs generated later). Access as `config.logo_url`.
- `booking_tile.dart` — **already extracted** (136 lines) as part of 098 implementation.
  `booking_overview_view.dart` is now 177 lines. Invoice button goes directly into `booking_tile.dart`
  alongside the existing Stripe invoice button — no extraction prerequisite.
  The tile uses `Get.find<MasterController>()` as local `ctrl` (NOT GetView) — use `ctrl.sendInvoice()`
  to match the existing pattern (lines 24, 97–98).
- `BookingModel` — `invoiceSentAt` already exists (added by 094_stripe_invoicing). Only add
  `invoiceNumber String?`. Do NOT re-add `invoiceSentAt`.
- `invoice_sent_at` column — already added by `094_stripe_invoicing.sql`. Do NOT add again.
- `MasterController` — currently 273 lines. Adding `sendInvoice()` (~15 lines) → ~288 lines.
  Still under 300 — no split required.

---

## Schema Changes

**Migration: `096_invoice_generation.sql`** (next after 095_chatbot_full.sql; 097 is menu)

```sql
ALTER TABLE bookings ADD COLUMN invoice_number text;

CREATE SEQUENCE IF NOT EXISTS invoice_seq START 1000;

CREATE OR REPLACE FUNCTION next_invoice_number()
RETURNS text LANGUAGE sql AS $$
  SELECT 'INV-' || LPAD(nextval('invoice_seq')::text, 5, '0')
$$;
```

Note: `invoice_sent_at` already exists — do NOT add it here.

**`setup.sh`** — add alongside other `flag_enabled` migrations:
```bash
if flag_enabled "INVOICES_ENABLED"; then run_always "096_invoice_generation.sql"; fi
```

---

## Edge Function

**`generate-invoice/index.ts`** — called internally by `stripe-dispatcher` AND from admin panel.

### Auth model (dual-caller)

Create the service-role `db` client **at the top** (before auth check) — it's needed for both
the role lookup and all subsequent DB calls:

```ts
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const serviceRoleKey    = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const db = createClient(SUPABASE_URL, serviceRoleKey)

const authHeader = req.headers.get('Authorization') ?? ''
const token = authHeader.replace('Bearer ', '')

let isAuthorized = false
if (token === serviceRoleKey) {
  isAuthorized = true  // internal call from stripe-dispatcher
} else {
  const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user } } = await anonClient.auth.getUser()
  if (user) {
    const { data: profile } = await db.from('profiles')
      .select('role').eq('user_id', user.id).single()
    isAuthorized = profile?.role === 'master'
  }
}
if (!isAuthorized) return json({ error: 'Unauthorized' }, 401)
```

### Flow

1. Load booking + service names + `business_config` (name, address, `logo_url`).
2. **If `booking.invoice_number` is already set, skip steps 2–3** (resend path — reuse existing
   number to preserve sequential integrity and original reference):
   ```ts
   const invoiceNumber = booking.invoice_number
     ?? (await db.rpc('next_invoice_number')).data as string
   if (!booking.invoice_number) {
     await db.from('bookings').update({ invoice_number: invoiceNumber }).eq('id', booking_id)
   }
   ```
3. Build PDF using `pdf-lib` (Deno-compatible — pure JS, no Node.js deps):
   ```ts
   import { PDFDocument, rgb, StandardFonts } from 'https://esm.sh/pdf-lib@1.17.1'
   ```
   Do NOT use `pdfmake` — it requires Node.js `fs`/`canvas` and fails in Deno even via esm.sh.
   Build layout programmatically: business header (name, address, logo if set), client name/email,
   service line items with date and price, invoice number, date, Stripe Payment Intent ID as
   reference, total amount.
4. Serialize and base64-encode using Deno std (NOT `Buffer` — Node.js global, unavailable in Deno):
   ```ts
   import { encodeBase64 } from 'https://deno.land/std@0.168.0/encoding/base64.ts'
   const pdfBytes = await pdfDoc.save()
   const pdfBase64 = encodeBase64(pdfBytes)
   ```
5. Send via Resend with PDF attachment:
   ```ts
   attachments: [{
     filename: `${invoiceNumber}.pdf`,
     content: pdfBase64,
   }]
   ```
6. Set `invoice_sent_at = now()` on booking row (always update to reflect latest send time).

### Modify `stripe-dispatcher/_handlers/booking.ts`

Add after the existing fetch calls (best-effort, same pattern as process-referral):
```ts
if (Deno.env.get('INVOICES_ENABLED') === 'true') {
  fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/generate-invoice`, {
    method: 'POST',
    headers: {
      Authorization:  `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ booking_id: bookingId }),
  }).catch(console.error)
}
```

---

## Flutter Changes

### `app_env.dart`
```dart
static const invoicesEnabled = bool.fromEnvironment(
  'INVOICES_ENABLED',
  defaultValue: false,
);
```

### `booking_tile.dart` — add PDF invoice button

`booking_tile.dart` is already extracted (136 lines). Add after the existing Stripe invoice block,
using `ctrl` (the local `Get.find<MasterController>()` variable already on line 24 — NOT `controller`):
```dart
if (AppEnv.invoicesEnabled && booking.status == 'confirmed') ...[
  TextButton(
    onPressed: () => ctrl.sendInvoice(booking.id),
    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
    child: Text(
      booking.invoiceNumber != null ? 'RESEND PDF INVOICE' : 'GENERATE PDF INVOICE',
      style: ETextStyles.labelSm.copyWith(color: EColors.onSurfaceMuted),
    ),
  ),
]
```

### `BookingModel` — add `invoiceNumber` only

`invoiceSentAt` already exists. Add:
```dart
final String? invoiceNumber;
```

`fromMap` mapping:
```dart
invoiceNumber: map['invoice_number'] as String?,
```

### `MasterController` — add `sendInvoice()`

```dart
Future<void> sendInvoice(String bookingId) async {
  try {
    final res = await SupabaseService.client.functions.invoke(
      'generate-invoice',
      body: {'booking_id': bookingId},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data?['error'] != null) {
      Get.snackbar('Error', data!['error'].toString());
      return;
    }
    Get.snackbar('Invoice sent', 'PDF invoice emailed to client');
    await loadAll();
  } catch (e) {
    Get.snackbar('Error', 'Could not generate invoice');
  }
}
```

---

## client.json / deliver.sh

```json
"INVOICES_ENABLED": "true"
```

`deliver.sh`:
```bash
INVOICES_ENABLED=$(json_get "INVOICES_ENABLED")

# In deploy block:
if [[ "${INVOICES_ENABLED:-false}" == "true" ]]; then
  deploy_fn "generate-invoice"
  supabase secrets set INVOICES_ENABLED=true  # stripe-dispatcher reads this at runtime
fi
```

Note for delivery: business logo must be in a **public** Supabase Storage bucket —
signed URLs expire and will break the PDF if generated later.

---

## Acceptance Criteria

- [ ] `INVOICES_ENABLED=false` — no invoice sent, no UI changes, `generate-invoice` not deployed
- [ ] Invoice email with PDF attachment received within 60s of `checkout.session.completed`
- [ ] PDF contains: business name/address, client name/email, services, date, amount, invoice number, Stripe reference
- [ ] Invoice number sequential (`INV-01000`, `INV-01001`, ...), never duplicated
- [ ] Resend reuses existing invoice number — does not generate a new one
- [ ] `invoice_sent_at` updated on booking row after every send
- [ ] Admin "RESEND PDF INVOICE" button visible when `invoiceNumber` is non-null
- [ ] Admin "GENERATE PDF INVOICE" button visible when `invoiceNumber` is null
- [ ] `booking_tile.dart` ≤ 300 lines after button addition
- [ ] `master_controller.dart` ≤ 300 lines after `sendInvoice()` addition
- [ ] All files ≤ 300 lines
- [ ] Internal stripe-dispatcher call uses `fetch()` not `supabase.functions.invoke()`
- [ ] Unauthorized callers return 401; non-master JWT returns 401
- [ ] `setup.sh` includes `flag_enabled "INVOICES_ENABLED"` migration line
