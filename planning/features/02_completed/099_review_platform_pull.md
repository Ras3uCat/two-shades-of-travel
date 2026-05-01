# Feature — Review Platform Pull (Google Reviews Import)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Low | **Complexity:** Low-Medium
**Flag:** `REVIEWS_SYNC_ENABLED=true` (dart-define in client.json)

---

## Objective

Auto-import Google Reviews into the `testimonials` table so they appear on the site without
manual copying. Requires a Google Places API key per client.

---

## What's Already in Place

- `testimonials` table (migration `030_testimonials.sql`) confirmed. Current columns:
  `id, author, role, quote, rating, display_order, is_active, created_at`.
  `rating` already exists — no change needed for that field.
  Missing: `source` and `external_id` — added by this migration.
- `TestimonialsSection` and admin view already consume all `testimonials` rows — imported
  reviews appear automatically once in the table.
- `send-reminders` cron pattern confirmed for the nightly Edge Function.
- `AppEnv.reviewsEnabled` already exists (`REVIEWS_ENABLED` flag for post-appointment review
  requests). Use distinct flag `REVIEWS_SYNC_ENABLED` to avoid collision.
- `sync-google-reviews` uses service-role key — bypasses RLS. Upsert works without policy changes.

---

## Schema Changes

**Migration: `098_reviews_sync.sql`**

Use `ADD COLUMN IF NOT EXISTS` — safe to re-run and guards against accidental double-application:

```sql
ALTER TABLE testimonials ADD COLUMN IF NOT EXISTS source      text NOT NULL DEFAULT 'manual'; -- 'manual' | 'google'
ALTER TABLE testimonials ADD COLUMN IF NOT EXISTS external_id text;

CREATE UNIQUE INDEX IF NOT EXISTS testimonials_external_id_idx ON testimonials (external_id)
  WHERE external_id IS NOT NULL;
```

No changes to `rating` or any other existing columns.

**`setup.sh`** — compound gate: both `testimonials` module AND `REVIEWS_SYNC_ENABLED` required.
`ALTER TABLE testimonials` fails if the testimonials table doesn't exist (module not enabled):
```bash
if [[ ",$MODULES," == *",testimonials,"* ]] && flag_enabled "REVIEWS_SYNC_ENABLED"; then
  run_always "098_reviews_sync.sql"
fi
```

---

## Edge Function

**`sync-google-reviews/index.ts`**

Cron: `0 3 * * *` (3am daily).

Flow:
1. Read `GOOGLE_PLACES_ID` + `GOOGLE_PLACES_API_KEY` + `REVIEWS_MIN_RATING` (default `'4'`)
   from `Deno.env`.
2. Call Google Places Details API:
   ```ts
   const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=reviews&key=${apiKey}`
   ```
   Returns up to 5 most recent reviews (Google free tier limit).
3. Filter: skip reviews with `rating < minRating`.
4. Upsert with `ignoreDuplicates: true` — inserts new reviews only, leaves existing rows
   completely untouched. This preserves admin curation (`is_active = false` on a hidden
   review will NOT be overwritten on the next sync):
   ```ts
   await db.from('testimonials').upsert(
     reviews.map(r => ({
       author:       r.author_name,
       role:         'Google Review',
       quote:        r.text,
       rating:       r.rating,
       source:       'google',
       external_id:  r.author_url,  // unique Google profile URL — one review per person per place
       is_active:    true,
       display_order: 999,
     })),
     { onConflict: 'external_id', ignoreDuplicates: true }
   )
   ```
   Use `r.author_url` (e.g. `https://www.google.com/maps/contrib/12345.../reviews`) as
   `external_id` — NOT `r.time.toString()`. `r.time` is a unix timestamp that could collide
   (two reviews posted the same second). `author_url` is guaranteed unique: Google only allows
   one review per person per place.
5. Log count inserted. Fail gracefully if API key is invalid (log error, return 200 — no crash).

---

## Flutter Changes

### `app_env.dart`
```dart
static const reviewsSyncEnabled = bool.fromEnvironment(
  'REVIEWS_SYNC_ENABLED',
  defaultValue: false,
);
```

No other Flutter changes. Imported reviews appear in `TestimonialsSection` automatically.

---

## client.json / deliver.sh

```json
"REVIEWS_SYNC_ENABLED": "true",
"GOOGLE_PLACES_ID": "ChIJ...",
"REVIEWS_MIN_RATING": "4"
```

`GOOGLE_PLACES_API_KEY` must NOT be in `client.json` — it is a sensitive API key.
Read from shell env only (same pattern as `ANTHROPIC_API_KEY`, `VAPID_PRIVATE_KEY`):

```bash
REVIEWS_SYNC_ENABLED=$(json_get "REVIEWS_SYNC_ENABLED")
GOOGLE_PLACES_ID=$(json_get "GOOGLE_PLACES_ID")
REVIEWS_MIN_RATING=$(json_get "REVIEWS_MIN_RATING")
# GOOGLE_PLACES_API_KEY must NOT be in client.json — read from shell env only
GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_API_KEY:-}"

if [[ "${REVIEWS_SYNC_ENABLED:-false}" == "true" ]]; then
  deploy_fn "sync-google-reviews"
  supabase secrets set \
    GOOGLE_PLACES_ID="$GOOGLE_PLACES_ID" \
    REVIEWS_MIN_RATING="${REVIEWS_MIN_RATING:-4}" \
    GOOGLE_PLACES_API_KEY="$GOOGLE_PLACES_API_KEY"
fi
```

Checklist item: cron schedule `0 3 * * *`, warn if `GOOGLE_PLACES_API_KEY` is empty.

---

## Delivery Guide

Add to post-golive checklist:
- Finding Places ID: Google Maps → search business → Share → Embed a map → extract `place_id=` param
- Google Cloud Console: enable Places API, create API key, restrict to Places API only
- Billing must be enabled on the Google Cloud project (required even for free-tier requests)
- `REVIEWS_MIN_RATING=4` filters 1–3 star reviews (set to `1` to import all)

---

## Acceptance Criteria

- [ ] `REVIEWS_SYNC_ENABLED=false` — no cron deployed, no schema change applied
- [ ] `testimonials` module not in MODULES — migration skipped even if `REVIEWS_SYNC_ENABLED=true`
- [ ] First run: Google reviews with `rating ≥ REVIEWS_MIN_RATING` appear in `TestimonialsSection`
- [ ] Subsequent runs: idempotent — no duplicates, existing rows untouched
- [ ] Admin sets `is_active = false` on a Google review — sync does NOT re-activate it
- [ ] `source = 'manual'` rows untouched by sync
- [ ] Invalid API key → error logged, function returns 200 (no crash)
- [ ] `REVIEWS_MIN_RATING` default of 4 filters 1–3 star reviews
- [ ] `GOOGLE_PLACES_API_KEY` is never written to `client.json`
- [ ] All files ≤ 300 lines
