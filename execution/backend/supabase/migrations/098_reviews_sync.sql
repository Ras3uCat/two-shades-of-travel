-- 098_reviews_sync.sql
-- Adds source + external_id to testimonials for Google Reviews import.
-- Only applied when testimonials module AND REVIEWS_SYNC_ENABLED are both active (see setup.sh).

ALTER TABLE testimonials ADD COLUMN IF NOT EXISTS source      text NOT NULL DEFAULT 'manual'; -- 'manual' | 'google'
ALTER TABLE testimonials ADD COLUMN IF NOT EXISTS external_id text;

CREATE UNIQUE INDEX IF NOT EXISTS testimonials_external_id_idx
  ON testimonials (external_id)
  WHERE external_id IS NOT NULL;
