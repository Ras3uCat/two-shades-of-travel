# Phase 10 — Analytics

This phase covers two distinct things:

1. **Built-in Admin Analytics Dashboard** — booking revenue and volume data, built into the app. Zero config, always on for master users.
2. **External Web Analytics** — visitor tracking (Cloudflare, Plausible, GA4). Configured per client via `index.html.tpl`.

---

## 10.0 — Built-in Admin Analytics Dashboard

The app includes a live analytics dashboard at **Admin → Analytics**. It is always visible to master users — no feature flag, no extra configuration needed. It queries booking data directly from Supabase.

### What it shows

| Widget | Data | Window |
|--------|------|--------|
| **Revenue (30d)** | Sum of confirmed/completed booking totals | Last 30 days |
| **Bookings (30d)** | Count of confirmed/completed bookings | Last 30 days |
| **Avg Booking Value** | Mean total per booking | Last 30 days |
| **Revenue Chart** | Bar chart — total revenue per week (12 wks) or month (6 mo) | Toggled by client |
| **Top Services** | Ranked horizontal bars — booking count per service | Last 90 days |
| **Busiest Days** | Bar chart — booking count by day of week | Last 90 days |

### Period toggle

The master user can switch between **Weekly** and **Monthly** views using the toggle in the top-right of the Analytics screen. The revenue chart re-fetches automatically on toggle.

### How it works

- Powered by the `get_revenue_summary(p_period)` Postgres function (`084_analytics.sql`)
- JWT role check inside the function — only `master` role can call it
- `fl_chart` package provides the bar charts (already in `pubspec.yaml` — no extra install needed)
- Empty states shown gracefully if there is no booking data yet

### Customisation

| Change | Where |
|--------|-------|
| Extend KPI cards (e.g. add cancellation rate) | `get_revenue_summary()` in `084_analytics.sql` + `analytics_view.dart` |
| Change the chart look / colours | `analytics_charts.dart` |
| Change the data windows (30d, 90d, 12wks) | `get_revenue_summary()` SQL |
| Add a new chart (e.g. revenue by artist) | Add a field to the JSON returned by `get_revenue_summary()`, add a widget in `analytics_charts.dart` |

> **Requires booking module.** The function queries the `bookings` table. Without the booking module the function is still created safely, but all charts will show empty states.

---

## 10.1 — External Web Analytics

Almost every client will ask "how many people visit my site?" Set up external analytics before handover.

---

## Option A — Cloudflare Analytics (free, zero config, privacy-friendly)

If hosting on Cloudflare Pages, analytics are built in — no script tag needed.
Go to: Pages project → **Analytics** tab. Shows visitors, page views, countries, devices.
Limitation: data is aggregated, not per-page for SPAs.

---

## Option B — Plausible Analytics (paid, privacy-friendly, great for EU clients)

[plausible.io](https://plausible.io) — $9/mo for up to 10k pageviews. GDPR-compliant, no cookies.
Best choice for clients with GDPR enabled.

Add to `web/index.html.tpl` before `</head>`:
```html
<script defer data-domain="acme.studio" src="https://plausible.io/js/script.js"></script>
```

---

## Option C — Google Analytics 4 (free, most familiar to clients)

1. Create a GA4 property at [analytics.google.com](https://analytics.google.com)
2. Get the Measurement ID (format: `G-XXXXXXXXXX`)
3. Add to `web/index.html.tpl` before `</head>`:

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

> **If `GDPR_ENABLED=true`:** The GDPR bridge is already built. Paste your GA4 snippet inside
> the `window.enableAnalytics()` function body in `web/index.html.tpl` (not directly in `<head>`).
> The app calls `window.enableAnalytics()` automatically when the user clicks Accept — analytics
> will not fire until then. An inline example snippet and full instructions are in the comments
> of `index.html.tpl`.
>
> **If `GDPR_ENABLED=false`:** Paste the analytics snippet directly in `<head>` as shown above —
> it will fire for all visitors immediately.

---

## Option D — Google Search Console (always recommended, free)

Not a traffic analytics tool but tells the client how their site performs in Google search
(impressions, clicks, ranking keywords, crawl errors).

1. Go to [search.google.com/search-console](https://search.google.com/search-console)
2. Click **Add property** → choose **Domain** (covers www + non-www automatically)
3. Enter the domain: `acme.studio`
4. **Verify ownership** — choose the method that fits your host:

   | Host | Easiest method |
   |------|---------------|
   | **Cloudflare** | DNS TXT record — GSC gives you a string like `google-site-verification=xxx`. Add it as a TXT record on the root (`@`) in Cloudflare DNS. Propagates in seconds. |
   | **Vercel / Netlify** | HTML file method — download the `googleXXXX.html` file GSC provides and drop it into `web/` before rebuilding. It will be included in `build/web/` automatically. |
   | **Firebase Hosting** | HTML file or DNS TXT (both work) |

5. Click **Verify** — if DNS: may take 30 seconds to a few minutes
6. Submit the sitemap: `https://acme.studio/sitemap.xml`

> Search Console takes **4–12 weeks** to show meaningful ranking data for a new domain. Set it
> up at launch. Tell the client upfront — otherwise they will chase you after week 1 asking why
> nothing shows up.

After adding any analytics script, rebuild:
```bash
./deliver.sh --skip-db --skip-functions
```

---

## Option E — Uptime Monitoring (always recommended, free)

Analytics show you traffic. Uptime monitoring tells you when the site is down — before the client
calls you. [UptimeRobot](https://uptimerobot.com) free tier monitors every 5 minutes and emails
you on failure.

1. Create a free account at [uptimerobot.com](https://uptimerobot.com)
2. Click **Add New Monitor**
3. Type: **HTTP(s)**
4. Friendly name: `acme-studio`
5. URL: `https://yourclientdomain.com`
6. Monitoring interval: 5 minutes
7. Alert contacts: your email
8. Click **Create Monitor**

This catches silent Supabase project pauses (free tier) and hosting outages immediately.

---

## Option F — Error Monitoring with Sentry (optional, recommended for booking clients)

If the client has the booking module (real money, real users), knowing about JS errors before
the client does is worth the setup time. [Sentry](https://sentry.io) free tier covers 5k errors/month.

1. Create a project at [sentry.io](https://sentry.io) → **JavaScript** platform
2. Get the DSN (looks like `https://xxx@yyy.ingest.sentry.io/zzz`)
3. Add to `web/index.html.tpl` before `</head>`:

```html
<script
  src="https://browser.sentry-cdn.com/7.x.x/bundle.min.js"
  crossorigin="anonymous"
></script>
<script>
  Sentry.init({
    dsn: "YOUR_SENTRY_DSN",
    environment: "production",
  });
</script>
```

> Replace `7.x.x` with the latest Sentry version. Check [docs.sentry.io](https://docs.sentry.io)
> for the current CDN URL.
