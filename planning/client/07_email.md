# Phase 7 — Email Setup (Resend)

---

## 7.1 — Add sending domain

1. Go to [resend.com/domains](https://resend.com/domains)
2. Click **Add domain**
3. Enter the client's domain (e.g. `acme.studio`)
4. Add the DNS records shown (SPF, DKIM, DMARC) at the client's DNS provider
5. Click **Verify** — Resend will confirm all records are live

> **DNS takes up to 24 hours to propagate.** Do this step the day before QA — not the morning of.
> Until the domain shows a green checkmark in Resend, transactional emails will fail silently.
> You can test delivery separately using Resend's "Send test email" once the domain is verified.

---

## 7.2 — Create API key

1. Go to [resend.com/api-keys](https://resend.com/api-keys)
2. Click **Create API key**, name it for the client (e.g. `acme-studio`)
3. Copy the key → add to Supabase secrets as `RESEND_KEY`
4. Also set `RESEND_KEY` in `client.json` to suppress the deliver.sh warning

> Each client should have their own Resend account or at minimum their own API key for clean
> billing separation and domain reputation isolation.

---

## 7.3 — Email-sending edge functions reference

All transactional emails go through Resend via Supabase Edge Functions. None of these are called
from Flutter directly — they are all server-side only.

| Function | Trigger | Recipients | Module |
|----------|---------|------------|--------|
| `send-notification` | Called by other functions | Client or staff | booking |
| `send-welcome` | Newsletter signup | Subscriber | newsletter |
| `send-reminders` | Cron (`0 10 * * *`) | Client (appointment reminder) | booking |
| `send-review-requests` | Cron (`0 12 * * *`) | Client (review request 2h after appointment) | booking + reviews |
| `send-sms-reminders` | Cron (`0 10 * * *`) | Client SMS via Twilio | booking + SMS_ENABLED |
| `send-recurring-payment-reminders` | Cron (`0 9 * * *`) | Client (pay link for upcoming recurring booking) | booking + RECURRING_ENABLED |
| `unsubscribe` | GET request via email footer link | — (no email sent; renders HTML) | newsletter |
| `cancel-booking` | Client or admin cancels | Staff (always) + client (if admin-initiated) | booking |
| `shop-webhook` | Stripe `checkout.session.completed` | Client (order confirmation) | shop |
| `process-referral` | Called by `stripe-webhook` | Referrer + referred person (promo codes) | referrals |

### send-notification email types

The `send-notification` function handles multiple email types keyed by the `type` field:

| `type` | Sent to | When |
|--------|---------|------|
| `confirmation` | Client | After Stripe payment confirmed |
| `cancellation` | Client | When admin cancels on their behalf |
| `staff_new_booking` | Assigned artist | After Stripe payment confirmed |
| `staff_cancellation` | Assigned artist | When any cancellation occurs |
| `reminder` | Client | 23–25h before appointment (via send-reminders cron) |
| `review_request` | Client | 2h after completed appointment (via send-review-requests cron) |

### Customising email content

Email subjects and bodies are hardcoded inside each Edge Function. To change wording:

1. Edit the relevant function file in `execution/backend/supabase/functions/<function-name>/index.ts`
2. Re-deploy: `supabase functions deploy <function-name>`
3. No rebuild of the Flutter app is needed — emails are purely server-side

### Supabase auth emails (separate from Resend)

Signup confirmation and password-reset emails are sent by Supabase directly (not via Resend).
Customise them under: `Authentication → Email Templates` in the Supabase dashboard.

Pre-written templates are included in:
- `execution/backend/supabase/templates/email/confirm_signup.txt`
- `execution/backend/supabase/templates/email/reset_password.txt`

Copy the content into the Supabase dashboard template editor manually — these files are reference
copies, not automatically applied.
