-- 081_recurring_payment.sql
-- Updates create_recurring_series() to support Stripe-gated payment per appointment.
-- When p_confirmed = FALSE, future bookings are created as 'pending' so the
-- send-recurring-payment-reminders function can email a Stripe Checkout link
-- N days before each appointment.

ALTER TABLE business_config
  ADD COLUMN IF NOT EXISTS recurring_payment_days_ahead INT NOT NULL DEFAULT 3;

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS recurring_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE;

-- Re-declare with p_confirmed param (TRUE = confirmed/reserve-only, FALSE = pending/Stripe).
CREATE OR REPLACE FUNCTION create_recurring_series(
  p_template_booking_id UUID,
  p_interval_days       INT,
  p_end_date            DATE,
  p_confirmed           BOOLEAN DEFAULT TRUE
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
  v_lock_id   UUID;
  v_status    TEXT;
BEGIN
  v_status := CASE WHEN p_confirmed THEN 'confirmed' ELSE 'pending' END;

  SELECT * INTO v_booking FROM bookings WHERE id = p_template_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking % not found', p_template_booking_id;
  END IF;

  INSERT INTO recurring_bookings (template_booking_id, interval_days, end_date)
  VALUES (p_template_booking_id, p_interval_days, p_end_date)
  RETURNING id INTO v_series_id;

  UPDATE bookings SET recurring_series_id = v_series_id WHERE id = p_template_booking_id;

  v_end_ts := p_end_date::TIMESTAMPTZ + INTERVAL '1 day';
  v_next   := v_booking.start_time + (p_interval_days || ' days')::INTERVAL;

  WHILE v_next < v_end_ts LOOP
    -- Check for conflict
    SELECT id INTO v_lock_id
    FROM   bookings
    WHERE  artist_id = v_booking.artist_id
      AND  status   NOT IN ('cancelled')
      AND  start_time < v_next + (v_booking.total_duration_minutes || ' minutes')::INTERVAL
      AND  start_time + (total_duration_minutes || ' minutes')::INTERVAL > v_next
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_lock_id IS NULL THEN
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
        v_status, v_series_id
      );
      v_created := v_created + 1;
    ELSE
      v_conflicts := v_conflicts || to_jsonb(v_next::DATE::TEXT);
      v_lock_id   := NULL;
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
