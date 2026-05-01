# Phase 8 — Assets, SEO & PWA

Most SEO and PWA files are **generated automatically** by `prepare.sh` (Step 5 of deliver.sh).
The source-of-truth files are `.tpl` templates — `prepare.sh` reads them, substitutes all
`CLIENT_*` tokens from `client.json`, and writes the final `index.html`, `manifest.json`,
`robots.txt`, and `sitemap.xml` into `web/`.

**Only favicon and icons still require manual replacement** — everything else is handled for you
once `client.json` is filled in.

---

## 8.0 — Writing effective SEO fields

These two fields in `client.json` are the primary SEO levers. Take 10 minutes to get them right —
they directly affect click-through rate from Google results.

**`SEO_TITLE`** — the `<title>` tag and OG title
- Ideal length: **50–60 characters** (Google truncates beyond ~60)
- Pattern: `Business Name — Primary Keyword + Location`
- Put the most important keyword near the front, not buried after the name
- Example: `"Acme Studio — Luxury Hair Salon in New York City"` ✓
- Avoid: `"Welcome to Acme Studio | We offer many services"` ✗

**`SEO_DESCRIPTION`** — the meta description (shown in search results below the title)
- Ideal length: **140–160 characters** (Google truncates beyond ~160)
- Should contain 1–2 natural keywords but read like a sentence, not a keyword list
- End with a call to action: "Book online today.", "Schedule your visit.", etc.
- Example: `"Bespoke hair colour and cuts in the heart of Manhattan. Award-winning stylists. Book your appointment online today."` ✓
- Avoid keyword stuffing: `"hair salon hair colour hair cut hair treatment NYC hair"` ✗

> **Note:** `<meta name="keywords">` is ignored by Google and Bing. Do not add it. The keywords
> that matter are the natural language words in your `SEO_TITLE`, `SEO_DESCRIPTION`, page headings
> (h1/h2), and the JSON-LD structured data — all of which this template populates automatically
> from `client.json`.

**OG Image (`OG_IMAGE`):** Make sure this URL is live and returns a 1200×630 image before launch.
A broken OG image looks unprofessional when the link is shared on social media.
Test at [opengraph.xyz](https://www.opengraph.xyz).

---

## 8.1 — Replace favicon and app icons

The template ships with the default Flutter blue icons. Every client needs their own.

**Files to replace in `web/`:**

| File | Size | Purpose |
|------|------|---------|
| `favicon.png` | 32×32 px | Browser tab icon |
| `icons/Icon-192.png` | 192×192 px | Android PWA icon |
| `icons/Icon-512.png` | 512×512 px | Android PWA splash / store |
| `icons/Icon-maskable-192.png` | 192×192 px | Adaptive icon (Android) |
| `icons/Icon-maskable-512.png` | 512×512 px | Adaptive icon large |

**Fastest workflow:**
1. Get the client's logo as SVG or high-res PNG (≥512 px)
2. Go to [realfavicongenerator.net](https://realfavicongenerator.net)
3. Upload the logo, configure background colour to match `COLOR_SURFACE`
4. Download the package — copy the relevant PNG files into `web/` and `web/icons/`

For maskable icons, the logo should be centred with ~20% padding (safe zone).
Realfavicongenerator handles this automatically.

---

## 8.2 — Image hosting for admin-editable content

Several fields in the admin panel expect a **full public URL** to an image:
- `hero_image_url` (Settings → Page Content)
- Staff `photo_url` (Team section)
- Service `image_url` (Services section)

The client will ask: *"Where do I upload images?"* Set the answer before handover.

**Recommended: Supabase Storage (simplest — already in use)**

Create a public bucket called `images` (or `assets`) for client-managed content:

1. Go to `Project → Storage → New bucket`
2. Name: `images`, Public: **ON**
3. The client uploads files via the Supabase dashboard (`Storage → images → Upload file`)
4. Right-click any uploaded file → **Copy URL** — paste that URL into the admin field

Instruct the client to upload images via the Supabase dashboard and copy the public URL.
Add their Supabase project as a `viewer` (they can access Storage as viewer — confirm this
in your Supabase plan).

**Recommended image sizes:**

| Field | Recommended size | Notes |
|-------|-----------------|-------|
| `hero_image_url` | 1920×1080 px, JPG | Compressed to <300 KB ideally |
| Staff `photo_url` | 400×400 px, JPG/PNG | Square crop, face centred |
| Service `image_url` | 800×600 px, JPG | 4:3 ratio works well in cards |

> Remind the client to compress images before uploading — [squoosh.app](https://squoosh.app)
> is free and browser-based. Uncompressed hero images (3–5 MB) will noticeably slow the site.

---

## 8.3 — manifest.json (automated)

`manifest.json` is generated automatically by `prepare.sh` from `web/manifest.json.tpl`.
All fields are populated from `client.json`:

| Field | Source in client.json |
|-------|----------------------|
| `name` | `CLIENT_NAME` |
| `short_name` | `SHORT_NAME` (defaults to first 12 chars of `CLIENT_NAME` if not set) |
| `background_color` | `COLOR_SURFACE` (with `#` added) |
| `theme_color` | `COLOR_PRIMARY` (with `#` added) |
| `description` | `SEO_DESCRIPTION` |

No manual editing of `manifest.json` is required. To change values, update `client.json` and
re-run `./deliver.sh`.

---

## 8.4 — index.html (automated)

`index.html` is generated automatically by `prepare.sh` from `web/index.html.tpl`. All `CLIENT_*`
tokens are read from `client.json` — no manual editing required.

| Token | client.json field |
|-------|------------------|
| `CLIENT_TITLE` | `SEO_TITLE` |
| `CLIENT_DESCRIPTION` | `SEO_DESCRIPTION` |
| `CLIENT_NAME` | `CLIENT_NAME` |
| `CLIENT_OG_IMAGE` | `OG_IMAGE` |
| `CLIENT_URL` | `SITE_URL` |
| `CLIENT_PHONE` | `PHONE` |
| `CLIENT_STREET` | `STREET` |
| `CLIENT_CITY` | `CITY` |
| `CLIENT_STATE` | `STATE` |
| `CLIENT_ZIP` | `ZIP` |
| `CLIENT_COUNTRY` | `COUNTRY` |
| `CLIENT_HOURS_JSON` | `HOURS_JSON` |
| `CLIENT_COLOR_SURFACE` | `COLOR_SURFACE` (loading screen background) |
| `CLIENT_COLOR_PRIMARY` | `COLOR_PRIMARY` (loading screen spinner) |

**`HOURS_JSON` format** (use this in `client.json` — remember to escape quotes):
```json
[{"@type":"OpeningHoursSpecification","dayOfWeek":"Monday","opens":"09:00","closes":"18:00"},...]
```

See `client.json.example` for the full pre-formatted value with all days.

---

## 8.5 — Verify the loading screen

The loading screen is built into `index.html`. It shows the client's brand surface colour with
a spinning ring in the primary colour immediately on page load, then fades out once Flutter
renders its first frame (`flutter-first-frame` event).

**After replacing `CLIENT_COLOR_SURFACE` and `CLIENT_COLOR_PRIMARY`:**
1. Build with `./deliver.sh --skip-db --skip-functions`
2. Open `build/web/index.html` in a browser directly (or `cd build/web && python3 -m http.server`)
3. Confirm the loading screen appears in the correct brand colours
4. Confirm it fades out once the app loads

> The spinner is intentionally minimal — a thin ring, no logo or text. This works universally
> across all 5 personalities. If the client wants a custom logo loader, that is a bespoke
> addition beyond the standard delivery scope.

---

## 8.6 — robots.txt (automated)

Generated automatically by `prepare.sh` from `web/robots.txt.tpl`. `SITE_URL` from `client.json`
is substituted for `CLIENT_URL`. `/admin` is always blocked from crawlers.

No manual editing required.

---

## 8.7 — sitemap.xml (automated)

`prepare.sh` generates `web/sitemap.xml` from scratch based on the `MODULES` in `client.json`.
Only routes for enabled modules are included. `SITE_URL` is the base URL.

No manual editing required for the initial build.

> If the `blog` module is enabled, `prepare.sh` automatically fetches all published blog post slugs
> from the Supabase REST API and adds them as `<url>` entries. No manual editing needed.
> After publishing new posts in the admin panel, re-run `./deliver.sh --skip-db --skip-functions`
> to regenerate the sitemap with the latest slugs.

---

## 8.8 — Rebuild

`./deliver.sh` (or `./deliver.sh --skip-db --skip-functions` for web-only changes) runs
`prepare.sh` automatically before the Flutter build. Just fill in `client.json` completely and
run the pipeline — no separate prepare step needed.

---

## Quick Reference — web/ Files Per Client

**Automated by `prepare.sh`** (update `client.json` only):

| File | Generated from | Populated by |
|------|---------------|-------------|
| `index.html` | `index.html.tpl` | All `CLIENT_*` tokens from client.json |
| `manifest.json` | `manifest.json.tpl` | CLIENT_NAME, SHORT_NAME, SEO_DESCRIPTION, COLOR_SURFACE, COLOR_PRIMARY |
| `robots.txt` | `robots.txt.tpl` | SITE_URL |
| `sitemap.xml` | Generated from scratch | SITE_URL + MODULES |

**Manual — replace before final build:**

| File | Size | Purpose |
|------|------|---------|
| `favicon.png` | 32×32 px | Browser tab icon |
| `icons/Icon-192.png` | 192×192 px | Android PWA icon |
| `icons/Icon-512.png` | 512×512 px | Android PWA splash / store |
| `icons/Icon-maskable-192.png` | 192×192 px | Adaptive icon (Android) |
| `icons/Icon-maskable-512.png` | 512×512 px | Adaptive icon large |

Use [realfavicongenerator.net](https://realfavicongenerator.net) to generate all five from the
client's logo.

---

## Quick Reference — index.html Token Index

| Token | Description |
|-------|-------------|
| `CLIENT_TITLE` | `<title>` tag and OG title |
| `CLIENT_DESCRIPTION` | Meta description and OG description |
| `CLIENT_NAME` | PWA app name and JSON-LD name |
| `CLIENT_OG_IMAGE` | Social share image URL (1200×630 px) |
| `CLIENT_URL` | Canonical URL (same as `SITE_URL`) |
| `CLIENT_PHONE` | E.164 phone (e.g. `+12125551234`) |
| `CLIENT_STREET` | Street address for JSON-LD |
| `CLIENT_CITY` | City for JSON-LD |
| `CLIENT_STATE` | State/region for JSON-LD |
| `CLIENT_ZIP` | Postal code for JSON-LD |
| `CLIENT_COUNTRY` | ISO country code (e.g. `US`) |
| `CLIENT_HOURS_JSON` | JSON-LD OpeningHoursSpecification array |
| `CLIENT_COLOR_SURFACE` | 6-char hex without `#` — loading screen background (matches `COLOR_SURFACE`) |
| `CLIENT_COLOR_PRIMARY` | 6-char hex without `#` — loading screen spinner colour (matches `COLOR_PRIMARY`) |
