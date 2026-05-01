-- =============================================================================
-- 000_base.sql — Always run for every client
-- =============================================================================

-- ─── Profiles ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id                         uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role                       text NOT NULL CHECK (role IN ('master', 'staff')),
  display_name               text,
  bio                        text,
  photo_url                  text,
  specialties                text[] DEFAULT '{}',
  stripe_express_account_id  text,
  stripe_onboard_status      text CHECK (stripe_onboard_status IN ('pending', 'verified', 'restricted')),
  timezone                   text NOT NULL DEFAULT 'America/New_York',
  created_at                 timestamptz NOT NULL DEFAULT now()
);

-- Auto-create profile on signup (role must be set manually after creation)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, role, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'staff'),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─── Business Config ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business_config (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name               text NOT NULL DEFAULT '',
  logo_url                  text,
  timezone                  text NOT NULL DEFAULT 'America/New_York',
  cancellation_hours        int NOT NULL DEFAULT 24,
  cancellation_refund_pct   int NOT NULL DEFAULT 100 CHECK (cancellation_refund_pct BETWEEN 0 AND 100),
  buffer_minutes            int NOT NULL DEFAULT 15,
  booking_interval_minutes  int NOT NULL DEFAULT 20,
  stripe_mode               text NOT NULL DEFAULT 'standard' CHECK (stripe_mode IN ('standard', 'connect_multi_staff')),
  created_at                timestamptz NOT NULL DEFAULT now()
);

-- Seed one row on fresh project
INSERT INTO business_config (client_name) VALUES ('')
ON CONFLICT DO NOTHING;

-- ─── Business Hours ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business_hours (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  weekday     int NOT NULL CHECK (weekday BETWEEN 1 AND 7),  -- 1=Mon, 7=Sun
  open_time   time NOT NULL DEFAULT '09:00',
  close_time  time NOT NULL DEFAULT '17:00',
  closed      bool NOT NULL DEFAULT false,
  UNIQUE (weekday)
);

-- Seed default Mon–Fri 9–5, Sat–Sun closed
INSERT INTO business_hours (weekday, open_time, close_time, closed) VALUES
  (1, '09:00', '17:00', false),
  (2, '09:00', '17:00', false),
  (3, '09:00', '17:00', false),
  (4, '09:00', '17:00', false),
  (5, '09:00', '17:00', false),
  (6, '10:00', '14:00', false),
  (7, '00:00', '00:00', true)
ON CONFLICT (weekday) DO NOTHING;

-- ─── Closures ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS closures (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date        date NOT NULL,
  reason      text,
  created_by  uuid REFERENCES profiles,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (date)
);

-- =============================================================================
-- RLS Policies
-- =============================================================================

ALTER TABLE profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_hours  ENABLE ROW LEVEL SECURITY;
ALTER TABLE closures        ENABLE ROW LEVEL SECURITY;

-- ─── profiles ────────────────────────────────────────────────────────────────
-- Read own profile (staff and master)
CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Master can read all profiles
CREATE POLICY "profiles_select_master"
  ON profiles FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- Update own profile only
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Master can update any profile
CREATE POLICY "profiles_update_master"
  ON profiles FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- ─── business_config ─────────────────────────────────────────────────────────
-- Anyone authenticated can read
CREATE POLICY "business_config_select_auth"
  ON business_config FOR SELECT
  USING (auth.role() = 'authenticated');

-- Only master can update
CREATE POLICY "business_config_update_master"
  ON business_config FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- ─── business_hours ──────────────────────────────────────────────────────────
-- Public read (needed for booking availability display)
CREATE POLICY "business_hours_select_public"
  ON business_hours FOR SELECT
  USING (true);

-- Only master can update
CREATE POLICY "business_hours_update_master"
  ON business_hours FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- ─── closures ────────────────────────────────────────────────────────────────
-- Public read
CREATE POLICY "closures_select_public"
  ON closures FOR SELECT
  USING (true);

-- Master can insert/update/delete
CREATE POLICY "closures_all_master"
  ON closures FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );
