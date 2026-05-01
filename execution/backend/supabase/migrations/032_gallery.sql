-- ─────────────────────────────────────────────────────────────────────────────
-- 032_gallery.sql — Gallery photos
-- ─────────────────────────────────────────────────────────────────────────────
-- PRE-REQUISITE: In the Supabase dashboard → Storage → New bucket:
--   Name: gallery  |  Public: ON
-- Without a public bucket, getPublicUrl() returns inaccessible URLs.

CREATE TABLE IF NOT EXISTS gallery_photos (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_path  TEXT        NOT NULL UNIQUE,
  caption       TEXT,
  display_order INTEGER     NOT NULL DEFAULT 0,
  is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE gallery_photos ENABLE ROW LEVEL SECURITY;

-- Public: read active photos only
CREATE POLICY "public_read_gallery"
  ON gallery_photos FOR SELECT
  USING (is_active = TRUE);

-- Master: full CRUD
CREATE POLICY "master_all_gallery"
  ON gallery_photos FOR ALL
  USING  ((auth.jwt() ->> 'role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'role') = 'master');
