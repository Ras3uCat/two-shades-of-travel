-- 010_booking.sql — Booking module migration
-- Run after 000_base.sql when MODULES includes 'booking'.
-- Timestamped: 2026-02-28

-- ─── Services catalog ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS services (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL,
  category         text NOT NULL,             -- free-form: "Hair", "Nails", etc.
  description      text,
  duration_minutes int  NOT NULL CHECK (duration_minutes > 0),
  price            numeric(10,2) NOT NULL CHECK (price >= 0),
  image_url        text,
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- ─── Artist ↔ Service many-to-many ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS artist_services (
  artist_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  PRIMARY KEY (artist_id, service_id)
);

-- ─── Bookings ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id                uuid NOT NULL REFERENCES profiles(id),
  client_name              text NOT NULL,
  client_email             text NOT NULL,
  service_ids              uuid[] NOT NULL,
  service_names            text[] NOT NULL,
  total_duration_minutes   int  NOT NULL CHECK (total_duration_minutes > 0),
  total_price              numeric(10,2) NOT NULL CHECK (total_price >= 0),
  start_time               timestamptz NOT NULL,
  end_time                 timestamptz NOT NULL,
  status                   text NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending','confirmed','cancelled','completed')),
  stripe_payment_intent_id text,
  promo_code_id            uuid REFERENCES promo_codes(id),
  created_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bookings_artist_time_idx ON bookings(artist_id, start_time);
CREATE INDEX IF NOT EXISTS bookings_status_idx      ON bookings(status);

-- ─── Promo codes ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS promo_codes (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code           text NOT NULL UNIQUE,
  artist_id      uuid REFERENCES profiles(id) ON DELETE CASCADE, -- NULL = global
  discount_type  text NOT NULL CHECK (discount_type IN ('percent','fixed')),
  discount_value numeric(10,2) NOT NULL CHECK (discount_value > 0),
  max_uses       int,
  uses_count     int NOT NULL DEFAULT 0,
  expires_at     timestamptz,
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- ─── Artist time-off ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS time_off (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  start_time timestamptz NOT NULL,
  end_time   timestamptz NOT NULL,
  reason     text,
  CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS time_off_artist_idx ON time_off(artist_id, start_time);

-- ─── RLS policies ────────────────────────────────────────────────────────────
ALTER TABLE services     ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_off     ENABLE ROW LEVEL SECURITY;

-- services: public read, master write
CREATE POLICY "services_public_read"
  ON services FOR SELECT USING (true);

CREATE POLICY "services_master_write"
  ON services FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'master')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'master');

-- artist_services: public read, master OR own staff write
CREATE POLICY "artist_services_public_read"
  ON artist_services FOR SELECT USING (true);

CREATE POLICY "artist_services_write"
  ON artist_services FOR ALL
  USING (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  )
  WITH CHECK (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  );

-- bookings: public insert (unauthenticated clients), staff see own, master sees all
CREATE POLICY "bookings_public_insert"
  ON bookings FOR INSERT WITH CHECK (true);

CREATE POLICY "bookings_staff_read_own"
  ON bookings FOR SELECT
  USING (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  );

CREATE POLICY "bookings_master_update"
  ON bookings FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'master');

-- promo_codes: staff read/write own, master all
CREATE POLICY "promo_codes_read"
  ON promo_codes FOR SELECT
  USING (
    artist_id = auth.uid() OR
    artist_id IS NULL OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  );

CREATE POLICY "promo_codes_write_own"
  ON promo_codes FOR ALL
  USING (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  )
  WITH CHECK (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  );

-- time_off: staff manage own, master manages all
CREATE POLICY "time_off_manage"
  ON time_off FOR ALL
  USING (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  )
  WITH CHECK (
    artist_id = auth.uid() OR
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'master'
  );

-- ─── get_artists_for_services(p_service_ids) ──────────────────────────────────
-- Returns profiles that offer ALL services in the given array.
CREATE OR REPLACE FUNCTION get_artists_for_services(p_service_ids uuid[])
RETURNS SETOF profiles
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT p.*
  FROM profiles p
  WHERE p.role IN ('master', 'staff')
    AND (
      SELECT COUNT(DISTINCT as2.service_id)
      FROM artist_services as2
      WHERE as2.artist_id = p.id
        AND as2.service_id = ANY(p_service_ids)
    ) = array_length(p_service_ids, 1)
  ORDER BY p.display_name;
$$;

-- ─── get_available_slots(p_artist_id, p_date_from, p_date_to, p_duration_minutes) ──
-- Returns time slots within business hours for the given artist + date range,
-- filtered to fit the required duration, excluding booked/time-off windows.
CREATE OR REPLACE FUNCTION get_available_slots(
  p_artist_id        uuid,
  p_date_from        timestamptz,
  p_date_to          timestamptz,
  p_duration_minutes int
)
RETURNS TABLE (
  id               text,
  artist_id        uuid,
  start_time       timestamptz,
  end_time         timestamptz,
  is_booked        boolean,
  is_direct_booked boolean
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
  v_config       business_config%ROWTYPE;
  v_interval_min int;
  v_buffer_min   int;
  v_cursor       timestamptz;
  v_day_start    timestamptz;
  v_day_end      timestamptz;
  v_slot_end     timestamptz;
  v_bh           business_hours%ROWTYPE;
  v_weekday      int;
  v_overlap      boolean;
  v_direct       boolean;
BEGIN
  -- Fetch business config
  SELECT * INTO v_config FROM business_config LIMIT 1;
  v_interval_min := COALESCE(v_config.booking_interval_minutes, 20);
  v_buffer_min   := COALESCE(v_config.buffer_minutes, 0);

  -- Iterate over each date in range
  v_cursor := date_trunc('day', p_date_from AT TIME ZONE 'UTC');

  WHILE v_cursor < p_date_to LOOP
    v_weekday := EXTRACT(ISODOW FROM v_cursor)::int;  -- 1=Mon, 7=Sun

    -- Get business hours for this weekday
    SELECT * INTO v_bh
    FROM business_hours
    WHERE weekday = v_weekday AND NOT closed
    LIMIT 1;

    IF FOUND THEN
      v_day_start := v_cursor + v_bh.open_time;
      v_day_end   := v_cursor + v_bh.close_time;

      -- Walk slots at interval
      DECLARE v_slot timestamptz := GREATEST(v_day_start, p_date_from);
      BEGIN
        WHILE v_slot + (p_duration_minutes || ' minutes')::interval <= v_day_end LOOP
          v_slot_end := v_slot + ((p_duration_minutes + v_buffer_min) || ' minutes')::interval;

          -- Check overlap with existing bookings or time_off
          SELECT EXISTS (
            SELECT 1 FROM bookings b
            WHERE b.artist_id = p_artist_id
              AND b.status NOT IN ('cancelled')
              AND b.start_time < v_slot_end
              AND b.end_time   > v_slot
          ) INTO v_overlap;

          IF NOT v_overlap THEN
            SELECT EXISTS (
              SELECT 1 FROM time_off t
              WHERE t.artist_id = p_artist_id
                AND t.start_time < v_slot_end
                AND t.end_time   > v_slot
            ) INTO v_overlap;
          END IF;

          -- Check closure days
          IF NOT v_overlap THEN
            SELECT EXISTS (
              SELECT 1 FROM closures c
              WHERE c.closure_date = v_cursor::date
            ) INTO v_overlap;
          END IF;

          -- Check direct booking (booking starts at this exact slot)
          IF v_overlap THEN
            SELECT EXISTS (
              SELECT 1 FROM bookings b
              WHERE b.artist_id  = p_artist_id
                AND b.status NOT IN ('cancelled')
                AND b.start_time = v_slot
            ) INTO v_direct;
          ELSE
            v_direct := false;
          END IF;

          id               := v_slot::text || '_' || p_artist_id::text;
          artist_id        := p_artist_id;
          start_time       := v_slot;
          end_time         := v_slot + (p_duration_minutes || ' minutes')::interval;
          is_booked        := v_overlap;
          is_direct_booked := v_direct;
          RETURN NEXT;

          v_slot := v_slot + (v_interval_min || ' minutes')::interval;
        END LOOP;
      END;
    END IF;

    v_cursor := v_cursor + '1 day'::interval;
  END LOOP;
END;
$$;

-- ─── book_appointment — row-locked insert ────────────────────────────────────
-- Locks the artist's booking rows for the time window, checks for conflicts,
-- and inserts the booking atomically.
CREATE OR REPLACE FUNCTION book_appointment(
  p_artist_id        uuid,
  p_service_ids      uuid[],
  p_service_names    text[],
  p_start_time       timestamptz,
  p_total_duration   int,
  p_total_price      numeric,
  p_client_name      text,
  p_client_email     text,
  p_promo_code_id    uuid DEFAULT NULL
)
RETURNS bookings
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
AS $$
DECLARE
  v_end_time timestamptz;
  v_config   business_config%ROWTYPE;
  v_buffer   int;
  v_conflict boolean;
  v_booking  bookings%ROWTYPE;
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

  -- Insert booking
  INSERT INTO bookings (
    artist_id, client_name, client_email,
    service_ids, service_names,
    total_duration_minutes, total_price,
    start_time, end_time, status, promo_code_id
  ) VALUES (
    p_artist_id, p_client_name, p_client_email,
    p_service_ids, p_service_names,
    p_total_duration, p_total_price,
    p_start_time, p_start_time + (p_total_duration || ' minutes')::interval,
    'confirmed', p_promo_code_id
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;
