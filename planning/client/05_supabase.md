# Phase 5 — Supabase Post-Deploy Configuration

These steps are done in the Supabase dashboard after `deliver.sh` completes.

---

## 5.1 — Set project secrets

Most secrets are **pushed automatically** by `deliver.sh` during Step 4. You only need to set two
secrets manually — both require values you won't have until after the site is live.

| Secret | Set by | Needed for |
|--------|--------|------------|
| `SUPABASE_URL` | Supabase (auto) | All functions |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase (auto) | All functions |
| `SUPABASE_ANON_KEY` | Supabase (auto) | All functions |
| `BUSINESS_NAME` | **deliver.sh (auto)** | Email subjects |
| `FROM_EMAIL` | **deliver.sh (auto)** | Email sender address |
| `TIMEZONE` | **deliver.sh (auto)** | Email timestamp formatting |
| `SITE_URL` | **deliver.sh (auto)** | Stripe redirect URLs |
| `RESEND_KEY` | **deliver.sh (auto)** | send-contact, send-notification, send-welcome |
| `STRIPE_SK` | **You — manual** | create-checkout, stripe-webhook |
| `STRIPE_WEBHOOK_SECRET` | **You — manual** (after Phase 6) | stripe-webhook signature verification |
| `STRIPE_SHOP_WEBHOOK_SECRET` | **You — manual** *(shop module only)* | shop-webhook signature verification |
| `STRIPE_SUBSCRIPTION_WEBHOOK_SECRET` | **You — manual** *(subscriptions module only)* | subscription-webhook signature verification |
| `STRIPE_EVENTS_WEBHOOK_SECRET` | **You — manual** *(events module only)* | event-webhook signature verification |
| `STRIPE_EVENTS_WEBHOOK_SECRET` | **You — manual** *(events module only)* | event-webhook signature verification |

Go to: `Project → Edge Functions → Secrets` to set the manual ones.

> `RESEND_KEY` must also appear in `client.json` so deliver.sh can push it. The key never goes
> into the Flutter build — it is only ever held in Supabase secrets at runtime.

---

## 5.2 — Configure Supabase Auth settings

Go to: `Project → Authentication → URL Configuration`

| Setting | Value |
|---------|-------|
| **Site URL** | `https://yourclientdomain.com` (exact value of `SITE_URL`) |
| **Redirect URLs** | Add `https://yourclientdomain.com/**` |

Without this, email confirmation links point to `localhost` and fail for real users.

Also check: `Project → Authentication → Providers → Email`
- **Confirm email:** leave ON for production
- Enable **Magic Link** here if the client wants passwordless login

> **Auth email rate limits:** The free Supabase plan uses shared SMTP, limited to ~3 auth emails
> per hour. On a busy booking day (staff sign-ups, password resets) this can throttle quickly.
> Fix: upgrade to Pro and enable custom SMTP under `Authentication → SMTP Settings`, or use
> a transactional provider like Resend directly as the SMTP relay.

---

## 5.3 — Customise Auth email templates

The default Supabase emails are Supabase-branded and generic. Pre-written templates are included
in the project — just open, personalise, and paste.

**Template files:** `backend/supabase/templates/email/`
- `confirm_signup.txt`
- `reset_password.txt`

Each file has `CLIENT_NAME` as a placeholder. Replace it with the actual business name, then paste
the content into the Supabase dashboard.

Go to: `Project → Authentication → Email Templates`

Update **Confirm signup** and **Reset password** at minimum.

```
Subject: Confirm your account — Acme Studio

Hi there,

Thanks for signing up with Acme Studio.

Please confirm your email address by clicking the link below:

{{ .ConfirmationURL }}

If you didn't create an account with us, you can safely ignore this email.

— The Acme Studio team
```

> The `{{ .ConfirmationURL }}` token is replaced by Supabase with the real link. Keep it exactly
> as shown.

---

## 5.4 — Register the JWT custom claims hook (critical for role routing)

The app routes `master` vs `staff` users based on a `user_role` claim in the JWT.

**Step 1 — Hook function is already deployed (automated)**

`deliver.sh` runs `001_auth_hook.sql` as part of the DB migrations step. The
`custom_access_token_hook` function is already created in your Supabase project. No SQL editor
work needed.

**Step 2 — Register the hook in the dashboard (manual — one click)**

Go to: `Project → Authentication → Hooks`
- Click **Add hook**
- Hook type: **Custom Access Token**
- Function: `public` → `custom_access_token_hook`
- Click **Save**

This one step cannot be automated via CLI — it must be done in the dashboard.

> Without this hook registered, `user_role` is absent from the JWT. The app will fail to route
> admin users to the correct views, and RLS policies that check `auth.jwt() ->> 'user_role'`
> will not work.

---

## 5.5 — Verify business_config (auto-seeded)

`deliver.sh` seeds `business_config` automatically from `client.json` (`CLIENT_NAME` and
`TIMEZONE`). After deploy, confirm the row exists:

```sql
SELECT * FROM business_config LIMIT 1;
```

Adjust `booking_advance_days`, `slot_duration_minutes`, and `currency` as needed for this client
via the Supabase SQL editor or Admin panel.

---

## 5.6 — Adjust business_hours (auto-seeded with defaults)

`deliver.sh` seeds 7 rows into `business_hours` automatically. The defaults are:
- Sunday: **closed**
- Monday–Friday: 09:00–18:00
- Saturday: 10:00–16:00

Update them to match this client's actual hours via the Admin panel
(Admin → Business Hours), or directly in SQL if the admin panel isn't deployed yet:

```sql
UPDATE business_hours SET open_time = '10:00', close_time = '20:00' WHERE day_of_week = 5;
UPDATE business_hours SET is_closed = true WHERE day_of_week = 0;
```

---

## 5.7 — Gallery Storage bucket (if gallery module)

Go to: `Project → Storage → New bucket`
- **Name:** `gallery` (must be exactly this)
- **Public:** ON
- Click **Create bucket**

---

## 5.8 — Schedule edge function crons

Up to five edge functions need scheduled triggers depending on which modules are enabled.
Set these in the Supabase dashboard: `Project → Edge Functions → [function name] → Schedule`

| Function | Recommended cron | When needed | What it does |
|----------|-----------------|-------------|--------------|
| `expire-pending-bookings` | `*/30 * * * *` | booking + Stripe | Auto-cancels unpaid pending bookings older than 30 min, releasing those slots |
| `send-reminders` | `0 10 * * *` | booking | Sends reminder emails 24h before each confirmed appointment (daily at 10am UTC) |
| `send-review-requests` | `0 12 * * *` | booking + `REVIEWS_ENABLED` | Sends "how was your visit?" emails after completed appointments (daily at noon UTC) |
| `send-sms-reminders` | `0 10 * * *` | `SMS_ENABLED` | Sends SMS reminders via Twilio 24h before each appointment (daily at 10am UTC) |
| `send-recurring-payment-reminders` | `0 9 * * *` | `RECURRING_ENABLED` + Stripe | Emails a Stripe Checkout payment link to clients with upcoming pending recurring bookings (daily at 9am UTC) |

> `expire-pending-bookings` is only needed when the `booking` module is enabled and `STRIPE_MODE`
> is not `none`. For non-Stripe clients, no bookings are created with `pending` status, so the
> function is harmless but unnecessary.
>
> `send-recurring-payment-reminders` is only needed when `RECURRING_ENABLED=true` **and** Stripe
> is configured. If you're using recurring bookings in reserve-only mode (no Stripe), this function
> is not deployed and future bookings are created as `confirmed` automatically.
> The number of days ahead to send the reminder is configurable in the Supabase SQL editor:
> ```sql
> UPDATE business_config SET recurring_payment_days_ahead = 3;
> ```

---

## 5.9 — RLS audit (security check)

Supabase silently leaves RLS **disabled** on any table created outside of migrations (e.g. via the
table editor during debugging). Before launch, verify every table has RLS enabled:

Go to: `Project → Table Editor` → click each table → confirm the **RLS enabled** badge is green.

Or run in the SQL editor:
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```
Every row should show `rowsecurity = true`. If any are `false`, enable them immediately:
```sql
ALTER TABLE <tablename> ENABLE ROW LEVEL SECURITY;
```
Then confirm that the existing policies are correct — an RLS-enabled table with no policies denies all access by default.

---

## Quick Reference — Supabase Secrets Index

| Secret | Set by | Needed for |
|--------|--------|------------|
| `SUPABASE_URL` | Supabase (auto) | All functions |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase (auto) | All functions |
| `SUPABASE_ANON_KEY` | Supabase (auto) | All functions |
| `BUSINESS_NAME` | **deliver.sh (auto)** | Email subjects |
| `FROM_EMAIL` | **deliver.sh (auto)** | Email sender |
| `TIMEZONE` | **deliver.sh (auto)** | Email timestamp formatting |
| `SITE_URL` | **deliver.sh (auto)** | Stripe redirect URLs |
| `RESEND_KEY` | **deliver.sh (auto)** | send-contact, send-notification, send-welcome |
| `STRIPE_SK` | **You — manual** | create-checkout, stripe-webhook |
| `STRIPE_WEBHOOK_SECRET` | **You — manual** (after webhook registered) | stripe-webhook signature verification |
| `STRIPE_SHOP_WEBHOOK_SECRET` | **You — manual** *(shop module only)* | shop-webhook signature verification |
| `STRIPE_SUBSCRIPTION_WEBHOOK_SECRET` | **You — manual** *(subscriptions module only)* | subscription-webhook signature verification |
| `STRIPE_EVENTS_WEBHOOK_SECRET` | **You — manual** *(events module only)* | event-webhook signature verification |
