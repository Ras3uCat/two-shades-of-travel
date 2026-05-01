# Phase 6 — Stripe Setup

Applies only when the `booking` module is enabled.

---

## 6.1 — Start with test mode

Always QA the full payment flow with Stripe test keys before going live.

In `client.json`, use `pk_test_...` for `STRIPE_PK`.
In Supabase secrets, set `STRIPE_SK` to `sk_test_...`.

Test card: `4242 4242 4242 4242` — any future expiry, any CVC.

Once QA passes and the client approves, follow the live key switchover checklist in **6.2** below.

---

## 6.2 — Stripe live key switchover checklist

Do these steps **in order** to avoid a gap where webhooks fire but can't be verified:

1. In Stripe dashboard, switch to **Live mode** (toggle top-left)
2. Get live keys: `Developers → API keys`
3. Update `client.json`: change `STRIPE_PK` from `pk_test_...` → `pk_live_...`
4. Update Supabase secret `STRIPE_SK`: `sk_test_...` → `sk_live_...`
5. Register a **new webhook endpoint** in Stripe live mode (same URL as test):
   - `https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook`
   - Event: `checkout.session.completed`
   - Copy the new **Signing secret** (`whsec_live_...`)
6. Update `client.json`: set `STRIPE_WEBHOOK_SECRET` to the new live signing secret
7. Push secrets + rebuild:
   ```bash
   ./deliver.sh --skip-db
   ```
8. Run one live test: make a real £1 / $1 booking (refund immediately from Stripe dashboard)
9. Confirm the webhook event shows `succeeded` in Stripe → Webhooks → live endpoint
10. Delete the test mode webhook endpoint in Stripe (prevents confusion)

> **Common mistake:** updating `STRIPE_SK` but forgetting to update `STRIPE_WEBHOOK_SECRET`.
> The webhook will 400 on every event (signature mismatch) and bookings will never confirm.

---

## 6.3 — Register the Stripe webhook

After the site is live on the real domain:

1. Go to [dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks)
2. Click **Add endpoint**
3. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook`
4. Events to listen for: `checkout.session.completed`
5. Click **Add endpoint**
6. Copy the **Signing secret** (starts with `whsec_`)
7. Set in `client.json`: `"STRIPE_WEBHOOK_SECRET": "whsec_..."`
8. Push to Supabase: `./deliver.sh --skip-db --skip-build`

> Register a separate webhook for test mode and one for live mode — different signing secrets.
> Delete the test endpoint once you switch to live keys.

---

## 6.4 — Connect mode: staff onboarding (connect_multi_staff only)

Each staff member must connect their Stripe Express account before they can receive bookings:

1. The master user navigates to Admin → Staff in the app
2. Clicks "Connect Stripe" for each staff member
3. Staff member completes the Stripe Express onboarding flow
4. Their `stripe_express_account_id` is stored in `staff_profiles`

> Until a staff member completes onboarding, their services cannot be booked.

---

## 6.5 — Subscriptions Stripe setup (subscriptions module only)

Subscriptions use a **separate webhook endpoint and signing secret** from the booking webhook.
Do not mix them.

### Step 1 — Create products and prices in Stripe

For each subscription plan the client wants to offer:

1. Stripe dashboard → **Products** → **Add product**
2. Fill in name, description, image (optional)
3. Under **Pricing**, choose **Recurring**, set the amount and interval (monthly / quarterly / yearly)
4. Save — copy the **Price ID** (starts with `price_`)
5. In the app: Admin → Subscription Plans → edit the plan → paste the Price ID into `stripe_price_id`

> Until a plan has a `stripe_price_id`, the Subscribe button shows a "Contact us" message instead
> of launching Stripe Checkout. This is intentional — plans can be created in the admin before
> Stripe is configured.

### Step 2 — Register the subscription webhook

1. Stripe dashboard → **Developers → Webhooks** → **Add endpoint**
2. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/subscription-webhook`
3. Events to listen for:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
4. Copy the **Signing secret** (starts with `whsec_`)
5. Set in `client.json`: `"STRIPE_SUBSCRIPTION_WEBHOOK_SECRET": "whsec_..."`
6. Push to Supabase: `./deliver.sh --skip-db --skip-build`

> This is a **different secret** from `STRIPE_WEBHOOK_SECRET` (used by the booking webhook).
> All four webhook secrets live in `client.json` — update there and re-run deliver.sh to rotate any of them.

### Step 3 — Decide what subscribers get

The subscription infrastructure is intentionally flexible. The `subscription-webhook` edge function
has `TODO` markers at the decision points:

| Decision | Where to implement |
|----------|--------------------|
| Subscribers get a booking discount | Use `booking_discount_pct` on the plan. Enforcement requires custom logic in the booking flow — add a check in `book_appointment()` Postgres function or in the Flutter `confirmBooking()` method. |
| Subscribers get X free services per month | Use `included_service_ids` on the plan. Track usage in a new `subscription_service_credits` table. |
| Send a welcome email on subscribe | Add Resend call in `subscription-webhook` under `checkout.session.completed`. |
| Notify client on payment failure | Add Resend call under `invoice.payment_failed`. |

None of these are required for the subscription module to work — clients can subscribe and be listed
in the admin without any of the above configured.

### Step 4 — (Optional) Recurring bookings with Stripe

If `RECURRING_ENABLED=true` and Stripe is configured, future recurring bookings are created as
`pending` and clients receive a payment link email before each appointment. No extra Stripe setup
is needed beyond the booking webhook already configured in Phase 6 — the
`send-recurring-payment-reminders` function reuses the existing `create-checkout` session flow.

---

## 6.6 — Referrals module setup (referrals module only)

The `referrals` module requires **no extra Stripe configuration**. Rewards fire automatically when
any booking payment completes — the `stripe-webhook` edge function calls `process-referral`
best-effort on every `checkout.session.completed` event.

### How it works end-to-end

1. Each authenticated user has a unique `referral_code` on their profile (generated automatically by `083_referrals.sql`)
2. They share their link: `https://yourclientdomain.com/booking?ref=XXXXXXXX`
3. When a referred person completes their first booking and pays via Stripe, `process-referral` fires automatically
4. Two promo codes are generated and emailed — one to the referrer (reward), one to the referred person (welcome gift)
5. The `referrals` table row is marked `rewarded_at = now()`

### What to configure

| Item | Where |
|------|-------|
| Reward discount % | `DISCOUNT_PCT` constant at top of `functions/process-referral/index.ts` (default: `10`) |
| Referrer email subject/body | `sendEmail(referrerEmail, ...)` call in the same file |
| Referred person email subject/body | `sendEmail(clientEmail, ...)` call in the same file |
| Insert codes into `promo_codes` table (if booking module present) | Uncomment the `TODO` block in `process-referral/index.ts` |

> Promo codes are stored as plain text on the `referrals` row (`referrer_promo_code`,
> `referred_promo_code`). They are **not** automatically enforced at checkout — enforcement requires
> the booking module's `promo_codes` table (uncomment the TODO block) or a custom validation step.

### Admin view

Admin → Referrals shows all referral records. The master user can filter by unrewarded and manually
mark records as rewarded (with custom promo codes) if a reward needs to be issued outside the
automatic flow.

---

## 6.7 — Shop Stripe webhook setup (shop module only)

The shop module uses a **separate webhook endpoint and signing secret** from the booking webhook.
Do not reuse `STRIPE_WEBHOOK_SECRET` — they must be registered independently.

### Step 1 — Register the shop webhook endpoint

1. Stripe dashboard → **Developers → Webhooks** → **Add endpoint**
2. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/shop-webhook`
3. Events to listen for: `checkout.session.completed`
4. Click **Add endpoint**
5. Copy the **Signing secret** (starts with `whsec_`)
6. Add to Supabase secrets:
   ```
   STRIPE_SHOP_WEBHOOK_SECRET = whsec_...
   ```
7. Also set `STRIPE_SHOP_WEBHOOK_SECRET` in `client.json` — `deliver.sh` uses this to push it to Supabase secrets on deploy

### Step 2 — Live key switchover (same pattern as 6.2)

When switching to live Stripe keys:
1. Re-register the shop webhook endpoint in **live mode** (separate from test mode)
2. Copy the new live signing secret
3. Update `STRIPE_SHOP_WEBHOOK_SECRET` in `client.json` and re-run `deliver.sh`
4. Or update the Supabase secret directly: `Supabase → Project Settings → Edge Functions → Secrets`

> **Symptoms of a missing/wrong `STRIPE_SHOP_WEBHOOK_SECRET`:**
> - Orders complete in Stripe but never appear in Admin → Orders
> - `shop-webhook` function logs show `400 Webhook signature verification failed`
> - Inventory is never decremented after a paid order

### Step 3 — Verify it works

After registering:
1. Make a test purchase (card `4242 4242 4242 4242`)
2. Check Stripe → Webhooks → shop endpoint — event should show `200`
3. Check Admin → Orders — order should appear with status `paid`
4. Check Supabase → Edge Functions → shop-webhook → Logs for any errors

---

## 6.8 — Events Stripe webhook setup *(events module only)*

The events module uses a **separate webhook endpoint and signing secret** from the booking webhook.
Do not reuse `STRIPE_WEBHOOK_SECRET` — register an independent endpoint for events.

> **Free events do not need Stripe at all.** Only configure this section if the client will sell paid event tickets.

### Step 1 — Register the event webhook endpoint

1. Stripe dashboard → **Developers → Webhooks** → **Add endpoint**
2. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/event-webhook`
3. Events to listen for: `checkout.session.completed`
4. Click **Add endpoint**
5. Copy the **Signing secret** (starts with `whsec_`)
6. Add to Supabase secrets:
   ```
   STRIPE_EVENTS_WEBHOOK_SECRET = whsec_...
   ```
7. Also set `STRIPE_EVENTS_WEBHOOK_SECRET` in `client.json` — `deliver.sh` uses this to push it to Supabase secrets on future re-deploys

### Step 2 — Live key switchover (same pattern as 6.2)

When switching to live Stripe keys:
1. Re-register the event webhook endpoint in **live mode** (separate from test mode)
2. Copy the new live signing secret
3. Update `STRIPE_EVENTS_WEBHOOK_SECRET` in `client.json` and re-run `deliver.sh`
4. Or update the Supabase secret directly: `Supabase → Project Settings → Edge Functions → Secrets`

> **Symptoms of a missing/wrong `STRIPE_EVENTS_WEBHOOK_SECRET`:**
> - Paid event tickets complete in Stripe but never confirm
> - `event-webhook` function logs show `400 Webhook signature verification failed`
> - Refunds fail or are not issued when an event is cancelled

### Step 3 — Verify it works

After registering:
1. Buy a test ticket for a paid event (card `4242 4242 4242 4242`)
2. Check Stripe → Webhooks → event endpoint — event should show `200`
3. Check Supabase → Table Editor → `event_tickets` — ticket status should be `confirmed`
4. Check Supabase → Edge Functions → event-webhook → Logs for errors
5. Check that the buyer received a confirmation email with their ticket code
