# Raspucat Client Delivery Guide
**Version:** 2.4

---

## How client.json is created

Most `client.json` values come directly from the **Raspucat discovery form** filled out by the client.
Once the quote is approved, generate and download `client.json` from the Raspucat admin panel.
The remaining `FILL_IN` fields (Supabase keys, Stripe keys, webhook secrets) are added by you during setup.
See [03_client-json.md](03_client-json.md) for the full list of what's pre-filled vs what needs manual input.

---

## Quick Delivery Checklist

Work through this top to bottom for every client. Each item links to the detailed doc.

> **Start Resend domain verification on day 0** — DNS takes up to 24h to propagate.
> Do it before anything else so it's green by the time you need it.

### Pre-delivery
- [ ] 1.1 — Client has completed the Raspucat discovery form and quote is approved
- [ ] 1.2 — Client email provisioned in Raspucat admin panel (`Provision Email`) — address forwarded to your inbox ([02_setup.md](02_setup.md) §1.2)
- [ ] 1.3 — Client has a live domain name
- [ ] 1.4 — Resend domain added and DNS records submitted ([07_email.md](07_email.md) §7.1)
- [ ] 1.5 — Stripe account exists (if booking or shop module) ([06_stripe.md](06_stripe.md) §6.1)

### Setup
- [ ] 2.1 — Supabase project created using the provisioned email — `SUPABASE_URL` + `SUPABASE_ANON_KEY` ready to paste ([02_setup.md](02_setup.md) §1.2)
- [ ] 2.2 — Setup script downloaded from Raspucat admin and run — scaffolds project, links Supabase CLI ([02_setup.md](02_setup.md) §0.5)
- [ ] 2.3 — `/inspo` run if `BRAND_INSPO_URLS` is non-empty — Brand Alignment Report reviewed and values refined ([02_setup.md](02_setup.md) §1.3)
- [ ] 2.4 — All `FILL_IN` values completed in `client.json` — Supabase keys, Stripe keys, RASPUCAT_ADMIN_TOKEN ([03_client-json.md](03_client-json.md) §2.2)
- [ ] 2.5 — `pubspec.yaml` `name` and `description` updated ([03_client-json.md](03_client-json.md) §2.3)

### Delivery pipeline
- [ ] 3.1 — Supabase CLI linked: `supabase link --project-ref ...` ([04_pipeline.md](04_pipeline.md) §Phase 3)
- [ ] 3.2 — `./deliver.sh` run successfully — no red errors ([04_pipeline.md](04_pipeline.md) §Phase 4)
- [ ] 3.3 — Stripe webhook registered: `./deliver.sh --register-webhooks` (requires `STRIPE_SK` set) or manually via Stripe dashboard after site is live ([06_stripe.md](06_stripe.md) §6.3)

### Manual Supabase config (post-deliver.sh)
- [ ] 4.1 — JWT custom claims hook registered in Supabase `Authentication → Hooks` ([05_supabase.md](05_supabase.md) §5.4)
- [ ] 4.2 — `STRIPE_SK` set in Supabase secrets (if booking/shop) ([05_supabase.md](05_supabase.md) §5.1)
- [ ] 4.3 — `STRIPE_WEBHOOK_SECRET` set (if booking) — register webhook after site is live ([06_stripe.md](06_stripe.md) §6.3)
- [ ] 4.4 — `STRIPE_SHOP_WEBHOOK_SECRET` set (if shop) — register webhook after site is live ([06_stripe.md](06_stripe.md) §6.7)
- [ ] 4.5 — `STRIPE_EVENTS_WEBHOOK_SECRET` set (if events) — register webhook after site is live ([06_stripe.md](06_stripe.md) §6.8)
- [ ] 4.6 — `STRIPE_SUBSCRIPTION_WEBHOOK_SECRET` set (if subscriptions) ([06_stripe.md](06_stripe.md) §6.5)
- [ ] 4.7 — Supabase auth `Site URL` and `Redirect URLs` set to live domain ([05_supabase.md](05_supabase.md) §5.2)
- [ ] 4.8 — Email templates customised in `Authentication → Email Templates` ([05_supabase.md](05_supabase.md) §5.3)
- [ ] 4.9 — Gallery Storage bucket created and set to **Public** (if gallery module) ([05_supabase.md](05_supabase.md) §5.7)
- [ ] 4.10 — Crons scheduled in Supabase dashboard ([05_supabase.md](05_supabase.md) §5.8):
  - [ ] `expire-pending-bookings` — `*/30 * * * *` (if booking)
  - [ ] `send-reminders` — `0 10 * * *` (if booking)
  - [ ] `send-review-requests` — `0 12 * * *` (if booking + `REVIEWS_ENABLED`)
  - [ ] `send-sms-reminders` — `0 10 * * *` (if `SMS_ENABLED`)
  - [ ] `send-recurring-payment-reminders` — `0 9 * * *` (if `RECURRING_ENABLED`)
  - *(no cron needed for `staff-calendar` — iCal feed is generated on-demand per request)*

### Assets and hosting
- [ ] 5.1 — Favicon + 5 PWA icon files replaced in `web/` ([08_assets.md](08_assets.md) §8.1)
- [ ] 5.2 — OG image uploaded and URL set in `client.json` ([08_assets.md](08_assets.md) §8.0)
- [ ] 5.3 — Deployed to hosting — `build/web/` pushed ([09_deploy.md](09_deploy.md))
- [ ] 5.4 — DNS pointed to host, `www` redirect confirmed ([09_deploy.md](09_deploy.md) §www redirect)
- [ ] 5.5 — Resend domain showing green verified status ([07_email.md](07_email.md) §7.1)
- [ ] 5.6 — Stripe webhook(s) registered now that site is live ([06_stripe.md](06_stripe.md) §6.3)
- [ ] 5.7 — Stripe Connect onboarding complete for each staff member (if `connect_multi_staff`) ([06_stripe.md](06_stripe.md) §6.4)

### QA
- [ ] 6.1 — All relevant sections of QA checklist passed ([12_qa-checklist.md](12_qa-checklist.md))
- [ ] 6.2 — JSON-LD validates at schema.org/SchemaValidator
- [ ] 6.3 — OG image loads correctly when URL pasted in Slack / iMessage
- [ ] 6.4 — No unreplaced `CLIENT_*` tokens in page source

### Handover
- [ ] 7.1 — Test data cleared from DB ([11_handover.md](11_handover.md) §13.0)
- [ ] 7.2 — Master user created and role set ([11_handover.md](11_handover.md) §11)
- [ ] 7.3 — Supabase 2FA enabled ([11_handover.md](11_handover.md) §Phase 11)
- [ ] 7.4 — Analytics + uptime monitor active ([10_analytics.md](10_analytics.md) §10.1)
- [ ] 7.5 — Search Console property verified, sitemap submitted ([10_analytics.md](10_analytics.md) §10.1)
- [ ] 7.6 — Handover email sent to client ([11_handover.md](11_handover.md) §13.8)
- [ ] 7.7 — **Stripe test → live key switchover** (if booking/shop) ([06_stripe.md](06_stripe.md) §6.2)

---

## Delivery Phases

### Core phases

| Phase | What | Doc | Est. time |
|-------|------|-----|-----------|
| **0** | Client discovery — questions, modules, brand, legal | [01_discovery.md](01_discovery.md) | 30–60 min |
| **0.5** | Provision client email → run setup script → scaffold project + link Supabase | [02_setup.md](02_setup.md) | 5 min |
| **0.6** | Inspiration analysis — `/inspo` → Brand Alignment Report → refine client.json *(skip if no BRAND_INSPO_URLS)* | [02_setup.md](02_setup.md) §1.3 | 10–15 min |
| **1** | Install prereqs, create Supabase project (using provisioned email) | [02_setup.md](02_setup.md) | 10 min |
| **2** | Fill in `client.json`, update `pubspec.yaml` | [03_client-json.md](03_client-json.md) | 15–30 min |
| **3** | Link Supabase CLI to project | [04_pipeline.md](04_pipeline.md) | 5 min |
| **4** | Run `./deliver.sh` — migrations, functions, build | [04_pipeline.md](04_pipeline.md) | 10–20 min |
| **5** | Post-deploy Supabase config (auth, JWT hook, crons, RLS) | [05_supabase.md](05_supabase.md) | 15–30 min |
| **6** | Stripe setup *(booking/shop modules only)* | [06_stripe.md](06_stripe.md) | 15 min |
| **7** | Resend email domain + API key | [07_email.md](07_email.md) | 10 min |
| **8** | Favicon, icons, SEO fields, PWA assets | [08_assets.md](08_assets.md) | 15–30 min |
| **9** | Deploy `build/web/` to hosting, DNS, www redirect | [09_deploy.md](09_deploy.md) | 15 min |
| **10** | Set up analytics and uptime monitoring | [10_analytics.md](10_analytics.md) | 15 min |
| **11** | Create master user in Supabase | [11_handover.md](11_handover.md) §11 | 5 min |
| **12** | QA checklist (all modules) | [12_qa-checklist.md](12_qa-checklist.md) | 30–60 min |
| **13** | Clean test data, client handover email, runbook | [11_handover.md](11_handover.md) §13 | 15–30 min |
| **14** | Post-go-live: adding modules, brand changes, key rotation | [13_post-golive.md](13_post-golive.md) | — |
| **19** | Raspucat admin integration — deliver.sh reporting, health monitoring | [19_raspucat-integration.md](19_raspucat-integration.md) | reference |

**Typical end-to-end time (no booking/Stripe):** 2–3 hours
**With booking + Stripe + full QA:** 3–5 hours

### Appendices (reference — not sequential)

| Doc | When to use |
|-----|-------------|
| [14_troubleshooting.md](14_troubleshooting.md) | Something broke |
| [15_mobile.md](15_mobile.md) | Client wants iOS/Android app builds |
| [16_shop.md](16_shop.md) | Shop module is enabled |
| [17_events.md](17_events.md) | Events module is enabled |
| [18_courses.md](18_courses.md) | Courses module is enabled |
| — | Staff calendar (iCal) — always-on, no appendix needed. See §6.8 in [06_stripe.md](06_stripe.md) for events webhook; staff subscribe at `/staff` |

---

## What's automated vs manual

### `deliver.sh` does automatically
- DB migrations (only for enabled modules, idempotent — safe to re-run)
- Edge function deploys
- Supabase secrets push: `BUSINESS_NAME`, `CLIENT_SLUG`, `FROM_EMAIL`, `TIMEZONE`, `SITE_URL`, `RESEND_KEY`, `STRIPE_SHOP_WEBHOOK_SECRET`, `STRIPE_EVENTS_WEBHOOK_SECRET`
- Token replacement on `.tpl` → `index.html`, `manifest.json`, `robots.txt`, `sitemap.xml`
- Blog post slugs fetched from Supabase and injected into `sitemap.xml` (when blog enabled)
- Flutter web build
- `pubspec.yaml` name + description patch from `CLIENT_SLUG` / `CLIENT_NAME`

### You do manually (one-time per client)
- Register JWT custom claims hook in Supabase dashboard (`Authentication → Hooks`)
- Set `STRIPE_SK` in Supabase secrets
- Register Stripe webhook endpoint(s): `./deliver.sh --register-webhooks` (automated) or Stripe dashboard (manual)
- Replace favicon and PWA icons in `web/`
- Schedule edge function crons in Supabase dashboard
- Create master user + set role in SQL editor
- Customise Supabase auth email templates in dashboard
- Create Supabase Storage bucket for gallery (if gallery module)

---

## Key files

| File | Purpose |
|------|---------|
| `execution/frontend/app/client.json` | **Source of truth** for all client config — gitignored, never commit |
| `execution/frontend/app/client.json.example` | Template to copy from |
| `execution/frontend/app/deliver.sh` | Full delivery pipeline |
| `execution/frontend/app/prepare.sh` | Web asset token replacement (called by deliver.sh) |
| `execution/frontend/app/prepare_mobile.sh` | Mobile asset + deep link setup |
| `execution/backend/supabase/migrations/` | SQL migration files |
| `execution/backend/supabase/functions/` | Edge function source |

---

## Template maintenance: propagating updates to existing clients

When you add a new feature to the master template and a client is already live:

### What never propagates automatically
Nothing. Each client directory is an isolated copy taken at delivery time. There is no link
back to the template.

### How to propagate a fix or feature to a live client

**Option A — targeted patch (for small, isolated changes)**
1. Identify the changed files in the master template (use `git diff` or `git log`)
2. Manually copy or apply those changes to the client's directory
3. Run `./deliver.sh` (or `./deliver.sh --skip-db` if only Flutter code changed)
4. Redeploy

**Option B — SQL-only changes (new migration)**
1. Copy the new `.sql` file to the client's `execution/backend/supabase/migrations/`
2. Run `supabase db push` in the client directory
3. No Flutter rebuild needed

**Option C — Edge Function update only**
1. Copy the updated function to the client's `execution/backend/supabase/functions/<fn-name>/`
2. Run `supabase functions deploy <fn-name> --project-ref <ref>`
3. No Flutter rebuild needed

### Tracking which clients have which version

Maintain a simple log in each client's repo root. Create `DELIVERY_LOG.md` at handover:

```markdown
# Delivery Log — Acme Studio

| Date | Change | Method |
|------|--------|--------|
| 2026-03-10 | Initial delivery | Full deliver.sh |
```

Add a row each time you patch. This prevents "did I already apply that fix?" confusion across
multiple clients.
