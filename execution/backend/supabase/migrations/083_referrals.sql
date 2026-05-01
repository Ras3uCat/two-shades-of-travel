-- 083_referrals.sql
-- Referral programme — standalone, no booking dependency.
-- Each authenticated client gets a unique referral_code on their profile.
-- Referral link: {SITE_URL}/booking?ref={code}  (or any module URL)
-- When a referred person completes their first booking, process-referral
-- edge function issues promo codes to both parties and marks rewarded_at.

-- ── Add referral_code to profiles ────────────────────────────────────────────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE
    DEFAULT substring(md5(gen_random_uuid()::text), 1, 8);

-- Back-fill any existing profiles that lack a code
UPDATE profiles
SET    referral_code = substring(md5(id::text || clock_timestamp()::text), 1, 8)
WHERE  referral_code IS NULL;

-- ── Referrals registry ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referrals (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_code        TEXT NOT NULL,            -- code that was used
  referrer_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  referred_email       TEXT NOT NULL,            -- email of the person who was referred
  booking_id           UUID REFERENCES bookings(id) ON DELETE SET NULL,  -- first qualifying booking
  rewarded_at          TIMESTAMPTZ,              -- null until reward issued
  referrer_promo_code  TEXT,                     -- reward code sent to referrer
  referred_promo_code  TEXT,                     -- reward code sent to referred person
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (referrer_id, referred_email)           -- one referral per pair
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer    ON referrals (referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred    ON referrals (referred_email);
CREATE INDEX IF NOT EXISTS idx_referrals_code        ON referrals (referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_unrewarded  ON referrals (rewarded_at) WHERE rewarded_at IS NULL;

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Master: full access
CREATE POLICY "master_all_referrals"
  ON referrals FOR ALL
  USING  ((auth.jwt() ->> 'user_role') IN ('master'))
  WITH CHECK ((auth.jwt() ->> 'user_role') IN ('master'));

-- Authenticated client: read their own referrals (as referrer)
CREATE POLICY "client_read_own_referrals"
  ON referrals FOR SELECT
  USING (referrer_id = auth.uid());

-- ── record_referral() ─────────────────────────────────────────────────────────
-- Called from the Flutter booking flow after confirmation.
-- Inserts a referral row if the code is valid and the pair is new.
-- Silently does nothing on invalid code or self-referral.
CREATE OR REPLACE FUNCTION record_referral(
  p_referral_code  TEXT,
  p_referred_email TEXT,
  p_booking_id     UUID DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_referrer_id UUID;
BEGIN
  -- Look up referrer by code
  SELECT id INTO v_referrer_id FROM profiles WHERE referral_code = p_referral_code;
  IF v_referrer_id IS NULL THEN RETURN; END IF;

  -- Prevent self-referral (compare profile id to auth uid of referred — best effort)
  IF v_referrer_id = auth.uid() THEN RETURN; END IF;

  INSERT INTO referrals (referral_code, referrer_id, referred_email, booking_id)
  VALUES (p_referral_code, v_referrer_id, lower(p_referred_email), p_booking_id)
  ON CONFLICT (referrer_id, referred_email) DO NOTHING;
END;
$$;

-- ── get_referral_stats() ──────────────────────────────────────────────────────
-- Returns summary stats for the authenticated user's referral activity.
CREATE OR REPLACE FUNCTION get_referral_stats()
RETURNS JSON
LANGUAGE sql
STABLE
AS $$
  SELECT json_build_object(
    'total',    COUNT(*),
    'rewarded', COUNT(*) FILTER (WHERE rewarded_at IS NOT NULL),
    'pending',  COUNT(*) FILTER (WHERE rewarded_at IS NULL)
  )
  FROM referrals
  WHERE referrer_id = auth.uid();
$$;
