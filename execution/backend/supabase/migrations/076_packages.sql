-- 076_packages.sql
-- Bundle/package deals: group services at a discounted or fixed price.
-- Optionally scoped to a specific artist (NULL = available with any artist).
-- Timestamped: 2026-03-06

-- ─── Packages table ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS packages (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text        NOT NULL,
  description    text,
  service_ids    text[]      NOT NULL DEFAULT '{}',
  discount_pct   integer     NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
  price_override decimal(10,2),           -- if set, overrides calculated price
  artist_id      uuid        REFERENCES profiles(id) ON DELETE CASCADE, -- NULL = all artists
  is_active      boolean     NOT NULL DEFAULT true,
  display_order  integer     NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- ─── Add package_id to bookings ───────────────────────────────────────────────
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS package_id uuid REFERENCES packages(id);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "packages_public_select"
  ON packages FOR SELECT
  USING (is_active = true);

CREATE POLICY "packages_admin_all"
  ON packages FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('master', 'staff'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('master', 'staff'))
  );

-- ─── book_appointment — re-declared with p_package_id support ─────────────────
-- Identical to 010_booking.sql except:
--   • p_package_id TEXT DEFAULT NULL added as final parameter
--   • package_id included in the INSERT
CREATE OR REPLACE FUNCTION book_appointment(
  p_artist_id        uuid,
  p_service_ids      uuid[],
  p_service_names    text[],
  p_start_time       timestamptz,
  p_total_duration   int,
  p_total_price      numeric,
  p_client_name      text,
  p_client_email     text,
  p_promo_code_id    uuid    DEFAULT NULL,
  p_package_id       text    DEFAULT NULL
)
RETURNS bookings
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
AS $$
DECLARE
  v_end_time   timestamptz;
  v_config     business_config%ROWTYPE;
  v_buffer     int;
  v_conflict   boolean;
  v_booking    bookings%ROWTYPE;
BEGIN
  SELECT * INTO v_config FROM business_config LIMIT 1;
  v_buffer   := COALESCE(v_config.buffer_minutes, 0);
  v_end_time := p_start_time + ((p_total_duration + v_buffer) || ' minutes')::interval;

  -- Acquire row-level lock on overlapping bookings
  PERFORM 1
  FROM bookings
  WHERE artist_id = p_artist_id
    AND status NOT IN ('cancelled')
    AND start_time < v_end_time
    AND end_time   > p_start_time
  FOR UPDATE;

  -- Recheck after lock
  SELECT EXISTS (
    SELECT 1 FROM bookings
    WHERE artist_id = p_artist_id
      AND status NOT IN ('cancelled')
      AND start_time < v_end_time
      AND end_time   > p_start_time
  ) INTO v_conflict;

  IF v_conflict THEN
    RAISE EXCEPTION 'BOOKING_CONFLICT: This slot is no longer available.';
  END IF;

  -- Apply promo code usage count if provided
  IF p_promo_code_id IS NOT NULL THEN
    UPDATE promo_codes
    SET uses_count = uses_count + 1
    WHERE id = p_promo_code_id
      AND is_active = true
      AND (max_uses IS NULL OR uses_count < max_uses)
      AND (expires_at IS NULL OR expires_at > now());

    IF NOT FOUND THEN
      RAISE EXCEPTION 'PROMO_INVALID: Promo code is expired or maxed out.';
    END IF;
  END IF;

  -- Insert booking (package_id cast from TEXT to UUID, null-safe)
  INSERT INTO bookings (
    artist_id, client_name, client_email,
    service_ids, service_names,
    total_duration_minutes, total_price,
    start_time, end_time, status,
    promo_code_id, package_id
  ) VALUES (
    p_artist_id, p_client_name, p_client_email,
    p_service_ids, p_service_names,
    p_total_duration, p_total_price,
    p_start_time, p_start_time + (p_total_duration || ' minutes')::interval,
    'confirmed',
    p_promo_code_id,
    p_package_id::uuid
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;
