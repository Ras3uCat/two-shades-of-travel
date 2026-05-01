# Phase 3 + Phase 4 — Supabase Link & Delivery Pipeline

---

## Phase 3 — Link Supabase CLI to Client Project

This must be done once per client project, from the backend directory:

```bash
cd execution/backend/supabase
supabase link --project-ref <YOUR_PROJECT_REF>
```

Get the project ref from the Supabase dashboard URL:
`https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

Verify the link:
```bash
supabase status
```

### Managing multiple active clients

`supabase link` writes to the local `.supabase/` config in the current directory. Since each client
lives in its own directory, they don't interfere. However, if you ever run CLI commands from the
wrong directory, you will push to the wrong project.

**Safe habit:** always confirm before running `supabase db push` or `supabase functions deploy`:
```bash
supabase status   # shows which project is currently linked
```

---

## Phase 4 — Run the Delivery Pipeline

> **Prerequisites before running `deliver.sh`:**
> 1. Phase 3 (`supabase link`) must be completed — run `supabase status` from `execution/backend/` to confirm.
> 2. `/inspo` must have been run and `client.json` finalised — the build bakes these values into the app. See [02_setup.md §1.3](02_setup.md).

From the frontend app directory:

```bash
cd execution/frontend/app
./deliver.sh
```

This runs 6 steps automatically:
1. **Tool checks** — confirms flutter, supabase, python3 are available
2. **Validate client.json** — required fields, module-conditional warnings
3. **DB migrations** — pushes the correct SQL files for enabled modules + seeds business_config/hours
4. **Edge functions** — deploys only the functions needed for active modules + pushes secrets
5. **Prepare web assets** — token replacement on `.tpl` files → `index.html`, `manifest.json`, `robots.txt`, `sitemap.xml`
6. **Flutter web build** — `flutter pub get` + `flutter build web --web-renderer html`

### Available flags

```bash
./deliver.sh --dry-run              # Print the plan, make no changes
./deliver.sh --skip-db              # Skip migrations (already applied)
./deliver.sh --skip-functions       # Skip edge function deploy
./deliver.sh --skip-build           # Skip Flutter build (DB/functions only)
./deliver.sh --mobile               # Also run prepare_mobile.sh for iOS/Android assets
./deliver.sh --register-webhooks    # Auto-register Stripe webhook + save signing secret to Supabase
```

> **`--register-webhooks`** calls the Stripe API to create a webhook endpoint pointing at the
> deployed `stripe-dispatcher` Edge Function, then writes `STRIPE_WEBHOOK_SECRET` directly to
> Supabase secrets. Requires `STRIPE_SK` to be set in Supabase secrets first. Idempotent — safe
> to re-run. Use instead of registering the webhook manually in the Stripe dashboard.

---

## What Gets Deployed (by module)

| Module | SQL Migration | Edge Functions |
|--------|---------------|----------------|
| *(always)* | `000_base.sql` | `send-contact`, `send-notification`, `staff-calendar` *(iCal feed — no module gate)* |
| *(always)* | `001_auth_hook.sql` — JWT role hook | — |
| *(always)* | `002_seed.sql` — business_config + business_hours | — |
| `booking` | `010_booking.sql` | `create-checkout`, `stripe-webhook` |
| `booking` + `connect_multi_staff` | — | + `connect-stripe-onboard` |
| `newsletter` | `020_newsletter.sql` | `send-welcome` |
| `newsletter` | `021_newsletter_unsubscribe.sql` — adds `unsubscribe_token` UUID column | `unsubscribe` |
| `testimonials` | `030_testimonials.sql` | — |
| `faq` | `031_faq.sql` | — |
| `gallery` | `032_gallery.sql` | — |
| `blog` | `033_blog.sql` | — |
| *(always)* | `040_booking_user_profile.sql` — user self-service cancel + own-booking RLS | — |
| *(always)* | `050_content_management.sql` — hero/CTA/services content columns + public RLS + staff profile public SELECT | — |
| *(always)* | `060_reminders_notes.sql` — `reminder_sent`, `review_request_sent`, `client_notes` columns | `send-reminders`, `send-review-requests` |
| *(always)* | `061_pending_booking.sql` — adds `p_initial_status` param to `book_appointment()` (Stripe pending flow + slot expiry) | `cancel-booking`, `cancel-pending-booking`, `expire-pending-bookings` |
| *(always)* | `070_deposit.sql` — adds `deposit_pct` (1–100, default 100) to business_config; controls partial deposit at booking. Configure in Admin → Settings → Booking Rules | — |
| `crm` | `062_crm.sql` — `get_client_summary()` Postgres function for admin Clients tab | — |
| `SMS_ENABLED` | `071_sms_phone.sql` — adds `client_phone` to bookings | `send-sms-reminders` |
| `GIFT_ENABLED` | `072_gift_vouchers.sql` — gift_vouchers table + RLS | `create-gift-checkout`, `apply-gift-voucher` |
| `INTAKE_ENABLED` | `073_intake_forms.sql` — intake_questions + intake_responses tables | — |
| `LOYALTY_ENABLED` | `074_loyalty.sql` — loyalty_ledger table | *(awarded by stripe-webhook)* |
| `WAITLIST_ENABLED` | `075_waitlist.sql` — waitlist table | *(notified by cancel-booking)* |
| `PACKAGES_ENABLED` | `076_packages.sql` — packages table; re-declares `book_appointment()` | — |
| *(always if booking)* | `077_staff_hours.sql` — staff_hours table; re-declares `get_available_slots()` | — |
| `REVIEWS_ENABLED` | `078_reviews.sql` — adds `review_token` to bookings; reviews table | `submit-review` |
| `CLIENT_PHOTOS_ENABLED` | `079_client_photos.sql` — client_photos table; **create private `client-photos` bucket manually** | — |
| `RECURRING_ENABLED` | `080_recurring_bookings.sql` — recurring_bookings table + `create_recurring_series()` + `cancel_recurring_series()` | — |
| `RECURRING_ENABLED` | `081_recurring_payment.sql` — adds `recurring_payment_days_ahead` to business_config + `recurring_reminder_sent` to bookings; re-declares `create_recurring_series()` with `p_confirmed` param | `send-recurring-payment-reminders` |
| `subscriptions` | `082_subscriptions.sql` — subscription_plans + subscriptions tables | `create-subscription-checkout`, `subscription-webhook` |
| `referrals` | `083_referrals.sql` — adds referral_code to profiles; referrals table; record_referral() + get_referral_stats() functions | `process-referral` |
| *(always if booking)* | `084_analytics.sql` — `get_revenue_summary(p_period)` Postgres function; returns 30-day KPIs, revenue by week/month, top services, busiest days | — |
| `shop` | `085_shop.sql` — product_categories, products, shop_discount_codes, shop_orders, shop_order_items tables; `validate_shop_discount()` Postgres function; RLS for public product browsing + client order history | `create-shop-checkout`, `shop-webhook` |
| `shop` + *(always if booking)* | `086_shop_analytics.sql` — replaces `get_revenue_summary()` to add shop_kpis, shop_revenue_by_period, top_products to the analytics response | — |
| `events` | `087_events.sql` — events, event_ticket_types, event_tickets tables; `purchase_event_tickets()` (row-locked, service_role-only), `get_ticket_availability()`, `cancel_event_tickets()` functions; RLS for public event browsing + master management | `create-event-checkout`, `event-webhook`, `cancel-event` |
| *(always)* | `088_calendar_tokens.sql` — `calendar_tokens` table (one UUID token per staff member); `regenerate_calendar_token()` SECURITY DEFINER function; RLS: staff read/update own row, master manages all | *(used by `staff-calendar` Edge Function)* |

> **Events module is OFF by default.** Add `events` to `MODULES` in `client.json` to enable it.
> Requires `STRIPE_EVENTS_WEBHOOK_SECRET` in `client.json` for paid events (register after site is live).
> Free events work without Stripe — confirmation happens immediately.

> **Shop module is OFF by default.** Add `shop` to `MODULES` in `client.json` to enable it.
> Requires `STRIPE_SHOP_WEBHOOK_SECRET` in client.json (set after registering the shop-webhook endpoint).
> `085_shop.sql` must be run before `086_shop_analytics.sql`. If both booking and shop are enabled,
> `deliver.sh` applies both in the correct order automatically.

> **Referral rewards** are issued automatically. The `process-referral` edge function is called
> best-effort from `stripe-webhook` every time a booking payment confirms. No manual wiring needed.
> The reward discount percentage is configurable via the `DISCOUNT_PCT` constant at the top of
> `functions/process-referral/index.ts` (default: 10%).

> `./deliver.sh` is safe to re-run on a live project. Migrations are idempotent by design
> (Supabase tracks which have been applied). Edge functions are simply overwritten in place.

---

## Raspucat Admin Reporting (automatic)

If `RASPUCAT_QUOTE_ID`, `RASPUCAT_API`, and `RASPUCAT_ADMIN_TOKEN` are all set in `client.json`,
`deliver.sh` automatically fires a series of non-blocking POSTs to the Raspucat admin system
**after a successful build**. These run even if `--skip-db` or `--skip-functions` are used, as
long as the build itself completes.

What happens automatically:

| Action | Trigger | Result |
|--------|---------|--------|
| Delivery progress update | Always | Marks `deliver_sh_complete` step as checked, sets portal stage → **Compiling** |
| Template version tracking | Always (if git HEAD available) | Records the git short hash as the template version on the quote |
| Stripe webhook auto-check | Only if `--register-webhooks` succeeded | Marks `stripe_webhooks_registered` delivery step as checked |
| Site registration | Only if `SITE_URL` is set | Writes `site_url` to the quote, creates UptimeRobot monitor, populates portal deliverables, marks `site_registered` + `uptime_robot_active` delivery steps |

> **None of these block the delivery.** If a Raspucat POST fails (e.g. no network, wrong token),
> deliver.sh prints a warning and continues. The delivery itself is not affected.

For full details on the Raspucat integration, see [19_raspucat-integration.md](19_raspucat-integration.md).
