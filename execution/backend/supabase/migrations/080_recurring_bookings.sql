-- 080_recurring_bookings.sql
-- Recurring / repeat bookings add-on.
-- Adds recurring_series_id to bookings + a recurring_bookings series table.
-- create_recurring_series() loops future dates with conflict detection.

-- ── Series registry ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recurring_bookings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  interval_days       INT  NOT NULL CHECK (interval_days > 0),
  end_date            DATE NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS recurring_series_id UUID REFERENCES recurring_bookings(id) ON DELETE SET NULL;

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE recurring_bookings ENABLE ROW LEVEL SECURITY;

-- Master: full access
CREATE POLICY "master_all_recurring"
  ON recurring_bookings FOR ALL
  USING  ((auth.jwt() ->> 'user_role') IN ('master'))
  WITH CHECK ((auth.jwt() ->> 'user_role') IN ('master'));

-- Anon/client: no direct access (managed through bookings)

-- ── create_recurring_series() ─────────────────────────────────────────────────
-- Called after a booking is confirmed.
-- Returns JSON: { series_id, created, conflicts: ["ISO date", ...] }
CREATE OR REPLACE FUNCTION create_recurring_series(
  p_template_booking_id UUID,
  p_interval_days       INT,
  p_end_date            DATE
) RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_booking   bookings%ROWTYPE;
  v_series_id UUID;
  v_next      TIMESTAMPTZ;
  v_end_ts    TIMESTAMPTZ;
  v_created   INT  := 0;
  v_conflicts JSONB := '[]'::JSONB;
  v_new_id    UUID;
BEGIN
  -- Load template booking
  SELECT * INTO v_booking FROM bookings WHERE id = p_template_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking % not found', p_template_booking_id;
  END IF;

  -- Create series record
  INSERT INTO recurring_bookings (template_booking_id, interval_days, end_date)
  VALUES (p_template_booking_id, p_interval_days, p_end_date)
  RETURNING id INTO v_series_id;

  -- Tag the template booking itself
  UPDATE bookings SET recurring_series_id = v_series_id WHERE id = p_template_booking_id;

  v_end_ts := p_end_date::TIMESTAMPTZ + INTERVAL '1 day';
  v_next   := v_booking.start_time + (p_interval_days || ' days')::INTERVAL;

  WHILE v_next < v_end_ts LOOP
    -- Conflict check: any non-cancelled booking for same artist overlapping this slot
    SELECT id INTO v_new_id
    FROM   bookings
    WHERE  artist_id = v_booking.artist_id
      AND  status   NOT IN ('cancelled')
      AND  start_time < v_next + (v_booking.total_duration_minutes || ' minutes')::INTERVAL
      AND  start_time + (total_duration_minutes || ' minutes')::INTERVAL > v_next
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_new_id IS NULL THEN
      -- No conflict — insert
      INSERT INTO bookings (
        artist_id, service_ids, service_names,
        start_time, total_duration_minutes, total_price,
        client_name, client_email, client_phone, client_notes,
        status, recurring_series_id
      ) VALUES (
        v_booking.artist_id, v_booking.service_ids, v_booking.service_names,
        v_next, v_booking.total_duration_minutes, v_booking.total_price,
        v_booking.client_name, v_booking.client_email,
        v_booking.client_phone, v_booking.client_notes,
        'confirmed', v_series_id
      );
      v_created := v_created + 1;
    ELSE
      v_conflicts := v_conflicts || to_jsonb(v_next::DATE::TEXT);
      v_new_id := NULL;
    END IF;

    v_next := v_next + (p_interval_days || ' days')::INTERVAL;
  END LOOP;

  RETURN json_build_object(
    'series_id', v_series_id,
    'created',   v_created,
    'conflicts', v_conflicts
  );
END;
$$;

-- cancel_recurring_series(): cancels all future confirmed bookings in a series
CREATE OR REPLACE FUNCTION cancel_recurring_series(p_series_id UUID)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  UPDATE bookings
  SET    status = 'cancelled'
  WHERE  recurring_series_id = p_series_id
    AND  status = 'confirmed'
    AND  start_time > now();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
