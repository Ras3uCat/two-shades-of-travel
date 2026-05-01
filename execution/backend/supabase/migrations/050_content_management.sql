-- 050_content_management.sql
-- Adds editable page-content columns to business_config so the admin can
-- update hero copy, section labels, and CTA text without a redeploy.
-- Also fixes RLS so the public homepage can read business_config,
-- and lets anonymous visitors see staff/master profiles (team section).
-- Timestamped: 2026-03-06

-- ─── business_config: new content columns ────────────────────────────────────
ALTER TABLE business_config
  ADD COLUMN IF NOT EXISTS hero_image_url    text,
  ADD COLUMN IF NOT EXISTS hero_overline     text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS hero_tagline      text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS services_overline text NOT NULL DEFAULT 'What We Offer',
  ADD COLUMN IF NOT EXISTS services_title    text NOT NULL DEFAULT 'Our Services',
  ADD COLUMN IF NOT EXISTS services_subtitle text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS cta_title         text NOT NULL DEFAULT 'Ready to Get Started?',
  ADD COLUMN IF NOT EXISTS cta_button_label  text NOT NULL DEFAULT 'Book Your Appointment';

-- ─── business_config: make SELECT public ─────────────────────────────────────
-- Business name, hero image, tagline etc. are public content — no auth needed.
DROP POLICY IF EXISTS "business_config_select_auth" ON business_config;

CREATE POLICY "business_config_select_public"
  ON business_config FOR SELECT
  USING (true);

-- ─── profiles: let public see staff/master bios for team section ──────────────
CREATE POLICY "profiles_select_public_staff"
  ON profiles FOR SELECT
  USING (role IN ('master', 'staff'));
