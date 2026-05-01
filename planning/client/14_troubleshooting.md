# Troubleshooting

---

## Admin panel not appearing after role is set

- The JWT is cached — the user must **sign out and sign back in** to get a fresh token
- Confirm the JWT hook is registered: `Authentication → Hooks` should show `custom_access_token_hook`
- Run `SELECT * FROM profiles WHERE email = 'owner@...'` to confirm the role column is set

---

## "supabase db push" fails

- Run `supabase status` to confirm the CLI is linked to the correct project
- Check that `supabase login` is current
- If migration was already applied: use `--skip-db` flag

---

## Flutter build fails

- Run `flutter pub get` manually first
- Check `flutter analyze` for errors
- Ensure `client.json` has all required fields (no empty strings)

---

## Email confirmation link goes to localhost

- Set **Site URL** in `Project → Authentication → URL Configuration` to the live domain
- Add the live domain to **Redirect URLs** as well
- Resend the confirmation email after updating

---

## Emails not sending / rate limited

- Check `RESEND_KEY` is set in Supabase secrets (not just in `client.json`)
- Confirm the sending domain is verified green in Resend dashboard
- If hitting the 3/hour auth email limit: enable custom SMTP in `Authentication → SMTP Settings`
- Check Edge Function logs: `Supabase → Edge Functions → send-notification → Logs`

---

## Stripe webhook not firing

- Confirm endpoint URL is exactly: `https://YOUR_REF.supabase.co/functions/v1/stripe-webhook`
- Check `STRIPE_WEBHOOK_SECRET` matches the signing secret in Stripe dashboard
- Confirm the webhook is registered on the correct mode (test vs live)

---

## Gallery photos not showing

- Confirm Storage bucket named exactly `gallery` exists and is set to **Public**
- Confirm photo path matches the actual path in the bucket (case-sensitive)
- Check RLS on `gallery_photos` — public read applies to `is_active = true` rows only

---

## Connect Stripe onboarding link fails

- Staff member must have a row in `staff_profiles` first (created by master admin)
- Check `connect-stripe-onboard` function logs in Supabase dashboard
- Confirm `SITE_URL` secret is set

---

## SPA routes return 404 on direct navigation

- Cloudflare/Netlify: confirm `_redirects` is present in `build/web/` after build
- Vercel: confirm `vercel.json` rewrite rule is in place
- Firebase: confirm `firebase.json` has a rewrite for `**` → `/index.html`

---

## Site went offline / Supabase project paused

- Free tier projects pause after 1 week of inactivity
- Restore: Supabase dashboard → project → **Restore project**
- Prevent: upgrade to Pro plan (`Project Settings → Billing`)

---

## How to read Edge Function logs

Every Edge Function writes to Supabase's built-in log viewer. This is the first place to check
when any server-side feature (emails, Stripe, bookings) stops working.

1. Supabase dashboard → **Edge Functions** (left sidebar)
2. Click the function name (e.g. `send-notification`, `stripe-webhook`, `shop-webhook`)
3. Click the **Logs** tab
4. Set the time range to cover when the failure occurred
5. Expand any red/error rows to see the full stack trace

> **Tip:** Open the Logs tab in a separate browser tab, then trigger the failing action in the
> app — the log entry appears within a few seconds.

Functions most likely to need log inspection:

| Function | What to look for |
|----------|-----------------|
| `stripe-webhook` | `400 Webhook signature verification failed` → wrong `STRIPE_WEBHOOK_SECRET` |
| `shop-webhook` | Same pattern — wrong `STRIPE_SHOP_WEBHOOK_SECRET` |
| `send-notification` | `401 Unauthorized` → `RESEND_KEY` not set or expired |
| `cancel-booking` | Stripe refund errors (non-fatal — cancellation still succeeds) |
| `create-checkout` | `Price not found` → service has no `price` set in DB |
| `book_appointment` (Postgres fn) | Check under `Database → Logs`, not Edge Functions |

---

## Shop webhook not firing / orders not appearing

1. Confirm `STRIPE_SHOP_WEBHOOK_SECRET` is set in Supabase secrets:
   `Project Settings → Edge Functions → Secrets`
2. Confirm the endpoint URL in Stripe is exactly:
   `https://YOUR_REF.supabase.co/functions/v1/shop-webhook`
3. In Stripe dashboard → Webhooks → click the shop endpoint → check **Recent deliveries** for the
   failing event — the response body will say what went wrong
4. Confirm you registered the webhook on the correct Stripe mode (test vs live)

---

## Booking slot not released after Stripe cancel

If a client abandons Stripe Checkout mid-session, the slot should free immediately via the
`cancel-pending-booking` edge function (triggered by the `cancelUrl` redirect).

If the slot stays blocked:
- Check that `cancelUrl` in `create-checkout` includes `?cancelled_booking_id=<id>` — it should
  be set automatically by `BookingController`
- The fallback is the `expire-pending-bookings` cron — runs every 30 min, frees any `pending`
  booking older than 30 minutes
- Manually free: `UPDATE bookings SET status = 'cancelled' WHERE id = '...' AND status = 'pending'`

---

## "Pay at appointment" booking showing wrong status

If a `deposit_pct=0` booking shows as `pending` instead of `confirmed`:

- The booking controller should set `initialStatus: 'confirmed'` when `!addons.isPaymentRequired`
- Check `booking_addons_controller.dart` — `depositPct` must be loaded from `business_config`
  before `confirmBooking()` is called
- Verify `business_config.deposit_pct = 0` in the DB:
  `SELECT deposit_pct FROM business_config LIMIT 1`

---

## Email not arriving (wrong template / missing variable)

Supabase auth emails (signup confirmation, password reset) are separate from Resend transactional
emails. Check the correct system:

| Email type | Configured in |
|------------|--------------|
| Signup confirmation | `Authentication → Email Templates` in Supabase dashboard |
| Password reset | `Authentication → Email Templates` |
| Booking confirmation | `send-notification` Edge Function → Resend |
| Staff notification | `send-notification` Edge Function → Resend |
| Cancellation | `send-notification` Edge Function → Resend |
| Welcome / newsletter | `send-welcome` Edge Function → Resend |
| Review request | `send-review-requests` Edge Function → Resend |
| Appointment reminder | `send-reminders` Edge Function → Resend |
| Shop order confirmation | `shop-webhook` Edge Function → Resend |

If a Resend email is not arriving:
1. Check Resend dashboard → **Logs** — look for the email and its delivery status
2. If status is `bounced` / `failed`: check the `to` address is valid
3. If no log entry at all: the Edge Function never called Resend — check function logs (see above)
4. If `401`: `RESEND_KEY` is wrong or not set as a Supabase secret

---

## "Continue with Google / Apple" button not showing

- `GOOGLE_AUTH_ENABLED` or `APPLE_AUTH_ENABLED` must be `"true"` in `client.json` (string, not boolean)
- Rebuild required — these are dart-defines, not runtime config
- Also requires the corresponding OAuth provider enabled in `Supabase → Authentication → Providers`

---

## Blog / gallery / FAQ content not appearing publicly

Most content tables have RLS policies that restrict public reads to `is_active = true` rows.
If content is saved in the admin but not visible on the public-facing page:

1. Open Supabase → Table Editor → the relevant table
2. Confirm the row has `is_active = true` (or `published_at IS NOT NULL` for blog posts)
3. Check RLS policies: `Database → Policies` → select the table — confirm the public `SELECT`
   policy exists and is enabled

---

## Event webhook not firing / paid tickets never confirm

Paid event tickets complete in Stripe but `event_tickets.status` stays `pending`:

1. Confirm `STRIPE_EVENTS_WEBHOOK_SECRET` is set in Supabase secrets:
   `Project Settings → Edge Functions → Secrets`
2. Confirm the endpoint URL registered in Stripe is exactly:
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/event-webhook`
   (not the booking webhook URL — these are separate registrations)
3. In Stripe → **Webhooks** → click the events endpoint → **Recent deliveries** — the response
   body will show the specific failure reason
4. Check `Supabase → Edge Functions → event-webhook → Logs` for error details
5. Confirm you registered the webhook in the correct Stripe mode (test vs live)
6. This webhook is entirely separate from `stripe-webhook` (bookings) and `shop-webhook` (shop) —
   each must be registered independently with its own signing secret

---

## Staff calendar feed not loading or not updating

**Feed URL returns 404 or empty file:**
1. Confirm the token is valid — check `Supabase → Table Editor → calendar_tokens`:
   ```sql
   SELECT * FROM calendar_tokens WHERE token = '<token-from-url>';
   ```
   If no row is found, the token has been regenerated — the staff member needs the new URL from `/staff`
2. Check `Supabase → Edge Functions → staff-calendar → Logs` for error details
3. Confirm `staff-calendar` was deployed — it should always be present regardless of modules

**Calendar is not updating with new bookings:**
- Most calendar apps cache feeds with a **12–24 hour** refresh cycle — this is expected behaviour
- To force an immediate refresh: use the calendar app's manual refresh/sync option
- Apple Calendar: right-click the calendar → **Refresh**; Google Calendar: Settings → find the calendar → **Refresh**

**Staff member wants to revoke their calendar link:**
- Admin → `/admin/staff` → calendar icon on the staff tile → **Regenerate Token**
- Or the staff member can do it themselves at `/staff` → **Regenerate token**
- The old URL will immediately return 404; the new URL is displayed straight away
