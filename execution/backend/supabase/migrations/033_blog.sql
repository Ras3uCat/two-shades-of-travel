-- ─────────────────────────────────────────────────────────────────────────────
-- 033_blog.sql — Blog posts
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS blog_posts (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         TEXT        NOT NULL UNIQUE,
  title        TEXT        NOT NULL,
  body         TEXT        NOT NULL DEFAULT '',
  cover_url    TEXT,
  is_published BOOLEAN     NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION update_blog_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  -- Auto-set published_at when first published
  IF NEW.is_published AND OLD.is_published = FALSE THEN
    NEW.published_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER blog_posts_updated_at
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW EXECUTE FUNCTION update_blog_updated_at();

ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Public: read published posts only
CREATE POLICY "public_read_blog"
  ON blog_posts FOR SELECT
  USING (is_published = TRUE);

-- Master: full CRUD including drafts
CREATE POLICY "master_all_blog"
  ON blog_posts FOR ALL
  USING  ((auth.jwt() ->> 'role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'role') = 'master');
