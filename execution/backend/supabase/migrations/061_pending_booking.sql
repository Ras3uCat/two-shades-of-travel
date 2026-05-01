-- 061_pending_booking.sql
-- Adds p_initial_status parameter to book_appointment() so Stripe-enabled
-- clients can create bookings as 'pending' until Stripe payment completes.
-- expire-pending-bookings Edge Function auto-cancels unpaid slots after 30 min.
-- Timestamped: 2026-03-07

-- Drop previous overloads created in 010 and 060 migrations
DROP FUNCTION IF EXISTS book_appointment(uuid, uuid[], text[], timestamptz, int, numeric, text, text, uuid);
DROP FUNCTION IF EXISTS book_appointment(uuid, uuid[], text[], timestamptz, int, numeric, text, text, uuid, text);

CREATE OR REPLACE FUNCTION book_appointment(
  p_artist_id        uuid,
  p_service_ids      uuid[],
  p_service_names    text[],
  p_start_time       timestamptz,
  p_total_duration   int,
  p_total_price      numeric,
  p_client_name      text,
  p_client_email     text,
  p_promo_code_id    uuid DEFAULT NULL,
  p_client_notes     text DEFAULT NULL,
  p_initial_status   text DEFAULT 'confirmed'
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

  -- Acquire row-level lock on overlapping non-cancelled bookings
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

  -- Insert booking with the caller-supplied initial status
  INSERT INTO bookings (
    artist_id, client_name, client_email,
    service_ids, service_names,
    total_duration_minutes, total_price,
    start_time, end_time, status, promo_code_id, client_notes
  ) VALUES (
    p_artist_id, p_client_name, p_client_email,
    p_service_ids, p_service_names,
    p_total_duration, p_total_price,
    p_start_time, p_start_time + (p_total_duration || ' minutes')::interval,
    p_initial_status, p_promo_code_id, p_client_notes
  )
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;
