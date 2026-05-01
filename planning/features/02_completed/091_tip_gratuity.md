# Feature — Tip / Gratuity at Checkout
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** FLOW | **Status:** BACKLOG
**Priority:** Medium | **Complexity:** Low
**Flag:** `TIP_ENABLED=true` (dart-define in client.json)

---

## Objective

Allow clients to optionally add a gratuity before being sent to Stripe Checkout. Common request
from salons, barbers, spas. Tip amount is added as a separate Stripe line item so it appears
clearly on the receipt. No payout logic changes needed for Standard mode; Connect mode tips
flow to the artist's connected account via `transfer_data`.

---

## What's Already in Place

- `create-checkout/index.ts` — already handles multiple line items; tip appends a second one.
  Destructured body: `booking_id, success_url, cancel_url, gift_voucher_code, loyalty_points_redeem`.
  Pattern for storing pre-session data on booking row already established (`loyalty_points_redeemed`,
  `gift_voucher_id` both stored here — same pattern for `tip_amount`).
- `BookingAddonsController` — reactive add-on state. Has deposit, SMS, gift voucher, loyalty.
  `reset()`, `chargeAmount()`, `depositDue()` all need updating for tip.
- `step4_confirmation_summary.dart` — `_ClientForm` holds the input fields (name, email, SMS, promo,
  gift, loyalty, notes). Tip selector goes here below notes. `_BookingSummaryCard` shows the price
  breakdown — tip line goes here.
- `BookingController.confirmBooking()` already calls `Get.find<BookingAddonsController>()` and
  passes addon values to `createCheckoutSession()`.
- `SupabaseBookingRepository.createCheckoutSession()` builds the body map and invokes
  `create-checkout` — needs `tip_amount_cents` added.
- Currency is hardcoded `'usd'` in `create-checkout` — tip line item must match, not use a
  `booking.currency` field (doesn't exist on the model).

---

## Schema Changes

**Migration: `091_tip.sql`**

```sql
ALTER TABLE bookings ADD COLUMN tip_amount integer NOT NULL DEFAULT 0; -- cents
```

No new tables. No RLS changes (bookings RLS already covers new columns).

---

## Edge Function Changes

**`create-checkout/index.ts`**

1. Destructure `tip_amount_cents` from request body (alongside existing fields).
2. If `tip_amount_cents > 0`: store on booking row (same pattern as `loyalty_points_redeemed`):
   ```ts
   await db.from('bookings').update({ tip_amount: tip_amount_cents }).eq('id', booking_id)
   ```
3. Append tip line item to `line_items`:
   ```ts
   if (tip_amount_cents > 0) {
     sessionParams.line_items.push({
       price_data: {
         currency: 'usd',        // matches existing hardcoded currency
         product_data: { name: 'Gratuity' },
         unit_amount: tip_amount_cents,
       },
       quantity: 1,
     })
   }
   ```
4. Add `tip_amount_cents` to session `metadata` for audit trail.

Connect mode: tip flows through `transfer_data.destination` automatically (it's part of the
session total — no extra logic needed).

**No new Edge Function required.**

---

## Flutter Changes

### `AppEnv`
```dart
static const tipEnabled = bool.fromEnvironment('TIP_ENABLED', defaultValue: false);
```
Note: `static const`, not `static bool get` — matches the pattern of every other flag in `app_env.dart`.

### `BookingAddonsController`
- Add `final tipAmountCents = 0.obs;` (int, cents)
- Add `void setTip(int cents) => tipAmountCents.value = cents;`
- Update `chargeAmount()` — tip is additive, not a discount:
  ```dart
  double chargeAmount(double totalPrice) {
    final discounted = totalPrice - giftDiscountDollars - loyaltyDiscountDollars;
    final withTip = (discounted < 0 ? 0 : discounted) + tipAmountCents.value / 100.0;
    return withTip;
  }
  ```
- Update `depositDue()` — no change needed; it calls `chargeAmount()` which now includes tip.
  Edge case: if `depositPct < 100`, the deposit percentage also applies to the tip (e.g. 50%
  deposit + $10 tip = $5 due now). This is acceptable for v1 — document in delivery guide.
- Add `tipDollars` getter: `double get tipDollars => tipAmountCents.value / 100.0;`
- Add `hasTip` getter: `bool get hasTip => tipAmountCents.value > 0;`
- Update `reset()`: add `tipAmountCents.value = 0;`

**Known edge case — gift voucher covers full service + user adds tip:**
In `confirmBooking()`, `charge = addons.chargeAmount(booking.totalPrice)` will equal just
the tip amount (discounts zeroed out the service cost). The code correctly proceeds to Stripe.
However, inside `create-checkout`, the service line item hits `STRIPE_MIN` (50 cents) because
discounts reduce it to 0. The client gets charged: $0.50 (service minimum) + tip. Over-charges
by $0.50. **Document as a known v1 limitation** — fix in v2 by skipping the service line item
when it would be ≤ 0 and tip > 0.

### `BookingRepository` (abstract)
Add `tipAmountCents` parameter to `createCheckoutSession`:
```dart
Future<String> createCheckoutSession({
  required String bookingId,
  required String successUrl,
  required String cancelUrl,
  String? giftVoucherCode,
  int loyaltyPointsRedeem = 0,
  int tipAmountCents = 0,      // new
});
```

### `SupabaseBookingRepository`
Add to `createCheckoutSession` body map:
```dart
if (tipAmountCents > 0) body['tip_amount_cents'] = tipAmountCents;
```

### `BookingController.confirmBooking()`
Pass tip when calling `createCheckoutSession`:
```dart
tipAmountCents: addons.tipAmountCents.value,
```

### `step4_confirmation_summary.dart` — **must split first (507 lines)**

`step4_confirmation_summary.dart` is already **507 lines** — a hard NEVER violation.
It must be split before adding anything. Suggested extraction:
- `tip_selector.dart` — `_TipSelector` widget
- `booking_summary_card.dart` — `_BookingSummaryCard`
- `client_form.dart` — `_ClientForm` + `_GiftVoucherField` + `_LoyaltyRow`
- `step4_confirmation_summary.dart` keeps only `Step4ConfirmationSummary` + `_ConfirmBar`

**`_ClientForm`** — add tip selector below the notes field, gated on `AppEnv.tipEnabled`:
```dart
if (AppEnv.tipEnabled) ...[
  const SizedBox(height: ESpacing.md),
  _TipSelector(addons: addons, controller: controller),
]
```

`_TipSelector` widget (`tip_selector.dart` — extract to its own file):
- Suggested amounts: None, 10%, 15%, 20% — calculated from `controller.totalPrice`
  (pre-discount service subtotal — tip on the full service value, not the discounted price)
- "Custom" option opens a text field for manual entry
- Tapping a preset calls `addons.setTip(cents)` and highlights the selected chip

**`_BookingSummaryCard`** — add tip line in the price breakdown (alongside gift/loyalty rows):
```dart
if (addons.hasTip) ...[
  const SizedBox(height: ESpacing.xs),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('GRATUITY', style: ETextStyles.label.copyWith(color: EColors.onSurfaceMuted)),
      Text('+ \$${addons.tipDollars.toStringAsFixed(2)}', style: ETextStyles.body),
    ],
  ),
],
```

---

## client.json / deliver.sh

```json
"TIP_ENABLED": "true"
```

`deliver.sh`: no new Edge Function to deploy. `create-checkout` redeploys automatically on
`deliver.sh` run (already in deploy list).

Add `091_tip.sql` to the migration run order in `setup.sh`.

---

## Delivery Guide

Add to `06_stripe.md`: enabling tips, how the Gratuity line item appears on Stripe Checkout
and receipt, behaviour with Connect (tip included in artist payout automatically).

---

## Acceptance Criteria

- [ ] `TIP_ENABLED=false` (default) — no tip UI, no change to existing checkout flow
- [ ] `TIP_ENABLED=true` — tip selector visible in step 4 below notes field
- [ ] Tip selector hidden when `deposit_pct == 0` (pay at appointment — no Stripe session)
- [ ] Selecting None → `tipAmountCents = 0`, no Gratuity line item in Stripe session
- [ ] Selecting 15% → correct cent value calculated from service subtotal
- [ ] Tip line visible in `_BookingSummaryCard` when `hasTip = true`
- [ ] DUE NOW updates to include tip amount
- [ ] `tip_amount` stored on booking row by `create-checkout` (before session created, not by webhook)
- [ ] Gratuity line item visible on Stripe Checkout page and receipt
- [ ] Connect mode: tip flows to artist account without extra logic
- [ ] `reset()` clears tip between sessions
- [ ] `step4_confirmation_summary.dart` split into 4 files before any additions (currently 507 lines)
- [ ] All resulting files ≤ 300 lines
