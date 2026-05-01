-- 099_multi_location.sql
-- Adds multi-location support (Option A: business_config stays single global row).
-- Only applied when LOCATIONS_ENABLED=true (see setup.sh).

-- ── locations table ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  address    text,
  city       text,
  phone      text,
  timezone   text NOT NULL DEFAULT 'UTC',
  is_active  boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read locations" ON locations
  FOR SELECT USING (true);

CREATE POLICY "admin write locations" ON locations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role IN ('master', 'staff')
    )
  );

-- ── business_hours: per-location rows (null = global / single-location fallback) ─
ALTER TABLE business_hours
  ADD COLUMN IF NOT EXISTS location_id uuid REFERENCES locations(id) ON DELETE SET NULL;

-- ── profiles: staff belong to one location (null = unassigned / global) ──────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS location_id uuid REFERENCES locations(id) ON DELETE SET NULL;

-- ── bookings: store which location the booking is at ─────────────────────────
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS location_id uuid REFERENCES locations(id) ON DELETE SET NULL;
