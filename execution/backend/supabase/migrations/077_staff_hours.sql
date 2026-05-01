-- 077_staff_hours.sql
-- Per-staff working hours: overrides global business_hours for a given artist/weekday.
-- When a staff_hours row exists for artist + weekday, get_available_slots() uses it
-- instead of the business_hours fallback.
-- Timestamped: 2026-03-06

-- ─── staff_hours table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff_hours (
  id         uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id  uuid    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  weekday    integer NOT NULL CHECK (weekday BETWEEN 1 AND 7),  -- 1=Mon, 7=Sun
  open_time  time    NOT NULL,
  close_time time    NOT NULL,
  is_closed  boolean NOT NULL DEFAULT false,
  UNIQUE (artist_id, weekday)
);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE staff_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff_hours_public_read"
  ON staff_hours FOR SELECT
  USING (true);

CREATE POLICY "staff_hours_own_write"
  ON staff_hours FOR ALL
  USING (
    auth.uid() = artist_id OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  )
  WITH CHECK (
    auth.uid() = artist_id OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- ─── get_available_slots — re-declared with per-staff hours support ────────────
-- Identical to 010_booking.sql except the working-hours lookup now:
--   1. Checks staff_hours for artist_id + weekday first.
--   2. Falls back to business_hours when no staff_hours row is found.
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
  v_sh           staff_hours%ROWTYPE;
  v_weekday      int;
  v_open         time;
  v_close        time;
  v_day_closed   boolean;
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

    -- Check per-staff hours first
    SELECT * INTO v_sh
    FROM staff_hours
    WHERE artist_id = p_artist_id AND weekday = v_weekday
    LIMIT 1;

    IF FOUND THEN
      -- Use staff-specific hours
      v_day_closed := v_sh.is_closed;
      v_open       := v_sh.open_time;
      v_close      := v_sh.close_time;
    ELSE
      -- Fall back to global business_hours
      SELECT * INTO v_bh
      FROM business_hours
      WHERE weekday = v_weekday AND NOT closed
      LIMIT 1;

      IF NOT FOUND THEN
        -- Business closed this weekday, no staff override either
        v_cursor := v_cursor + '1 day'::interval;
        CONTINUE;
      END IF;

      v_day_closed := false;
      v_open       := v_bh.open_time;
      v_close      := v_bh.close_time;
    END IF;

    -- Skip closed days
    IF NOT v_day_closed THEN
      v_day_start := v_cursor + v_open;
      v_day_end   := v_cursor + v_close;

      -- Walk slots at interval
      DECLARE v_slot timestamptz := GREATEST(v_day_start, p_date_from);
      BEGIN
        WHILE v_slot + (p_duration_minutes || ' minutes')::interval <= v_day_end LOOP
          v_slot_end := v_slot + ((p_duration_minutes + v_buffer_min) || ' minutes')::interval;

          -- Check overlap with existing bookings
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
