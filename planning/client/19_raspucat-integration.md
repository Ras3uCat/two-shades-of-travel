# Phase 19 — Raspucat Admin Integration

This doc covers the full integration between `deliver.sh` / the modular project and the
Raspucat admin system (your own business dashboard at raspucat.com).

---

## Overview

The Raspucat admin system gives you a central dashboard to manage all client projects:
delivery checklists, portal access, billing, uptime monitoring, and Lighthouse scores.
The integration is built into `deliver.sh` — once configured, the entire connection is
**fully automatic** with no manual steps per client.

---

## One-Time Raspucat System Setup

> **Do this once — not per client.** These are global settings on your Raspucat Supabase
> project. Once set, every future client gets monitoring automatically on their first deploy.

### 1. Set Raspucat Supabase secrets

Go to **Raspucat Supabase Dashboard → Project Settings → Edge Functions → Secrets** and add:

| Secret | Value | Where to get it |
|--------|-------|-----------------|
| `UPTIMEROBOT_API_KEY` | Your UptimeRobot API key | [uptimerobot.com](https://uptimerobot.com) → My Settings → API Settings → Main API Key |
| `UPTIMEROBOT_WEBHOOK_SECRET` | Any random string you choose | Generate with: `openssl rand -hex 24` |
| `PAGESPEED_API_KEY` | Google PageSpeed Insights API key | [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials → Create API Key → restrict to PageSpeed Insights API |

### 2. Schedule the uptime polling cron

In **Raspucat Supabase Dashboard → Edge Functions → poll-uptime-status → Schedule**:

- Cron expression: `*/30 * * * *` (every 30 minutes)

This calls UptimeRobot's `getMonitors` API every 30 minutes and updates `uptime_status` on
each quote. Status transitions (down/up) are logged to `site_events` automatically.

> **Why polling instead of webhooks?** UptimeRobot webhooks require a paid Team/Enterprise plan.
> The polling approach works on the free tier (50 monitors) and is sufficient for a health
> dashboard — 30-min resolution is fine for visibility. No webhook secret needed.
>
> **Free tier limit:** 50 monitors. For 50+ clients, upgrade to UptimeRobot Pro (~$7/mo, 1000
> monitors). The polling function handles pagination automatically — no code changes needed.

### 3. Schedule the Lighthouse audit cron

In **Raspucat Supabase Dashboard → Edge Functions → run-lighthouse-audits → Schedule**:

- Cron expression: `0 3 * * 1` (every Monday at 3am UTC)

This runs weekly Google PageSpeed Insights audits for all active client sites and writes
performance, accessibility, best-practices, and SEO scores to each quote. Scores appear
in the admin drawer with a Δ delta from the previous audit.

> The function handles rate limiting automatically. For ≤57 clients it audits all at once.
> For larger rosters it staggers audits across the week so each client is audited on a
> fixed day (client row index % 7). PSI errors are logged + skipped — the cron never crashes.

---

## Per-Client Setup (at project start)

### client.json fields

Add these three fields to `client.json` at the start of every Raspucat-managed delivery:

```jsonc
"RASPUCAT_QUOTE_ID":    "uuid-of-the-quote-in-admin-dashboard",
"RASPUCAT_API":         "https://gegwqywgbgzahnftppda.supabase.co",
"RASPUCAT_ADMIN_TOKEN": "your-raspucat-admin-password"
```

- **`RASPUCAT_QUOTE_ID`** — Open the Raspucat admin dashboard, click the client's quote.
  The UUID is visible in the URL or in the detail drawer. Copy it here.
- **`RASPUCAT_API`** — Always the same Supabase URL. Never changes between clients.
- **`RASPUCAT_ADMIN_TOKEN`** — Your Raspucat admin password. Same one you log in with.

> Keep `RASPUCAT_ADMIN_TOKEN` out of version control. `client.json` is gitignored — it
> is never committed. The token is only used locally by `deliver.sh` at build time.

### What SITE_URL does

`SITE_URL` is a separate field you already fill in for every client. When `deliver.sh` runs
with `SITE_URL` set alongside the three Raspucat fields, the site health integration fires
automatically. No extra setup needed.

---

## What Happens Automatically on Each deliver.sh Run

```
deliver.sh ──→ Build completes ──→ Raspucat reporting block (non-blocking)
                                      │
                                      ├─ POST admin-delivery-progress
                                      │     step: deliver_sh_complete ✓
                                      │     portal stage → Compiling
                                      │     template_version: <git short hash>
                                      │
                                      ├─ POST admin-delivery-progress  (if --register-webhooks succeeded)
                                      │     step: stripe_webhooks_registered ✓
                                      │
                                      └─ POST admin-register-site  (if SITE_URL is set)
                                            writes site_url to quote
                                            creates UptimeRobot monitor
                                            populates portal deliverables
                                            step: site_registered ✓
                                            step: uptime_robot_active ✓
```

All POSTs are **fire-and-forget** — they do not block the build and a failure prints a
warning but does not abort the delivery.

---

## Portal Stage Progression (automatic)

The client-facing portal shows a stage indicator that updates automatically as you work:

| Stage | Set when | What the client sees |
|-------|----------|----------------------|
| **Transmitting** | Quote created | "We're building your site" |
| **Compiling** | `deliver_sh_complete` step checked | "Your site is being compiled" |
| **Deployed** | `smoke_test_passed` step checked (manually) | "Your site is live" |

You do not manually set the stage — it moves automatically as delivery steps are checked.
The `smoke_test_passed` step is checked manually in the Delivery tab of the admin drawer
after you complete QA and the site is confirmed live.

---

## Portal Deliverables (auto-populated)

When `admin-register-site` runs (triggered by deliver.sh), it populates the following
entries in the client's portal deliverables automatically:

| Deliverable | Value |
|-------------|-------|
| Live site | `SITE_URL` |
| Admin panel | `SITE_URL/auth` |
| Supabase project | `supabase.com/dashboard/project/<ref>` (if supabase_project_ref is set on the quote) |
| Booking admin | `SITE_URL/admin/bookings` (if `booking` in modules) |
| Shop admin | `SITE_URL/admin/shop` (if `shop` in modules) |
| Events admin | `SITE_URL/admin/events` (if `events` in modules) |

Additional deliverables (repo links, brand kit zip, DNS records, credentials) are added
manually in the portal's Deliverables section.

---

## Site Health Monitoring (automatic after first deploy)

Once `admin-register-site` runs:

1. **UptimeRobot monitor created** — checks the site every 5 minutes. Downtime triggers
   a webhook that immediately updates the client's `uptime_status` in the Raspucat database.
2. **Health badge appears** on the client's row in the admin dashboard — green/amber/red/grey
   dot based on uptime status + Lighthouse scores.
3. **Weekly Lighthouse audits** — scores appear in the Site Health section of the admin drawer
   with delta from the previous audit.
4. **Site events log** — downtime start/end events are logged and shown in the drawer.

> Cancelling a client's subscription automatically pauses/deletes their UptimeRobot monitor
> via the `admin-cancel-subscription` edge function. No manual cleanup needed.

---

## Template Version Tracking

Every time `deliver.sh` runs, it captures the git short hash of the modular project repo:

```bash
git -C <modular_project_root> rev-parse --short HEAD
```

This hash is recorded as the `template_version` on the quote. The Raspucat admin dashboard
shows:
- The installed template version on each client's quote row
- An **"Update Available"** badge when a newer deploy has been made (i.e. the modular project
  has advanced since this client was last delivered)
- A **"Mark Updated to \<hash\>"** button in the admin drawer that syncs the version

---

## Delivery Checklist (admin drawer → Delivery tab)

The Delivery tab in each client's quote drawer shows a checklist of all delivery steps.
Steps are grouped into phases:

| Phase | Key steps |
|-------|-----------|
| **Setup** | Quote created, client briefed, `client.json` configured |
| **Deploy** | `deliver_sh_complete` ✓ (auto), Stripe webhooks registered ✓ (auto if `--register-webhooks`) |
| **Post-Deploy** | DNS configured, custom domain live, Supabase auth URLs updated |
| **QA** | Smoke test passed ✓ (manual — sets portal stage to Deployed), booking flow tested |
| **Handover** | Handover email sent, client credentials set up, portal access granted |

Auto-checked steps (marked with a lock icon) are set by `deliver.sh` or the system.
Manual steps are toggled by clicking the checkbox in the admin drawer.

---

## Troubleshooting

### deliver.sh shows "Raspucat progress POST failed"

- Confirm `RASPUCAT_QUOTE_ID`, `RASPUCAT_API`, and `RASPUCAT_ADMIN_TOKEN` are all set and not `FILL_IN`
- Confirm you have an internet connection during the build
- Check that `RASPUCAT_ADMIN_TOKEN` matches the password you log in to Raspucat with
- The build still succeeds — this is non-blocking

### UptimeRobot monitor not created

- Confirm `SITE_URL` is set in `client.json` and starts with `https://`
- Confirm `UPTIMEROBOT_API_KEY` is set in Raspucat Supabase secrets
- Check the `admin-register-site` logs in Raspucat Supabase → Logs → Edge Functions
- Monitors can also be created manually: in the admin drawer → Details tab → Site URL field → Save

### Lighthouse scores not appearing

- Confirm `PAGESPEED_API_KEY` is set in Raspucat Supabase secrets
- Confirm the `run-lighthouse-audits` cron is scheduled (Supabase → Edge Functions → schedule)
- PSI requires the site to be publicly reachable — scores won't appear for localhost or private staging URLs
- Scores populate once per week; check back after the next Monday 3am UTC run

### Health badge not showing on a quote row

The badge only appears when `site_url` is set on the quote. If `admin-register-site` didn't
fire automatically, enter the URL manually in the admin drawer → Details tab → Site URL field.

---

## Secrets Reference

| Where | Secret | What it's for |
|-------|--------|----------------|
| Raspucat Supabase secrets | `UPTIMEROBOT_API_KEY` | Creating/deleting monitors + polling `getMonitors` API |
| Raspucat Supabase secrets | `PAGESPEED_API_KEY` | Running PageSpeed Insights audits |
| client.json (per-client) | `RASPUCAT_QUOTE_ID` | Links this client to their Raspucat quote |
| client.json (per-client) | `RASPUCAT_API` | Raspucat Supabase URL (same for all clients) |
| client.json (per-client) | `RASPUCAT_ADMIN_TOKEN` | Auth for deliver.sh → Raspucat API calls |
