-- 071_sms_phone.sql
-- Adds client_phone (nullable) to bookings for SMS reminders.
-- Re-declares book_appointment() with the new p_client_phone parameter appended
-- so existing callers that omit it continue to work (DEFAULT NULL).

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS client_phone TEXT;

-- ──────────────────────────────────────────────────────────────────────────────
-- book_appointment()
-- Full re-declaration. Changes from 010_booking.sql:
--   • Accepts p_client_phone TEXT DEFAULT NULL
--   • Stores client_phone in the INSERT
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.book_appointment(
  p_artist_id          UUID,
  p_service_ids        UUID[],
  p_service_names      TEXT[],
  p_start_time         TIMESTAMPTZ,
  p_total_duration     INTEGER,
  p_total_price        NUMERIC,
  p_client_name        TEXT,
  p_client_email       TEXT,
  p_promo_code_id      UUID    DEFAULT NULL,
  p_client_notes       TEXT    DEFAULT NULL,
  p_initial_status     TEXT    DEFAULT 'pending',
  p_client_phone       TEXT    DEFAULT NULL
)
RETURNS SETOF public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_end_time    TIMESTAMPTZ;
  v_final_price NUMERIC;
  v_booking     public.bookings;
BEGIN
  -- Compute end time from duration
  v_end_time := p_start_time + (p_total_duration * INTERVAL '1 minute');

  -- Conflict check with row-level lock to prevent double-booking
  PERFORM 1
    FROM public.bookings
   WHERE artist_id  = p_artist_id
     AND status    NOT IN ('cancelled')
     AND start_time < v_end_time
     AND end_time   > p_start_time
  FOR UPDATE;

  IF FOUND THEN
    RAISE EXCEPTION 'SLOT_TAKEN';
  END IF;

  -- Start with the quoted price
  v_final_price := p_total_price;

  -- Apply promo code discount if provided
  IF p_promo_code_id IS NOT NULL THEN
    DECLARE
      v_discount_type  TEXT;
      v_discount_value NUMERIC;
    BEGIN
      SELECT discount_type, discount_value
        INTO v_discount_type, v_discount_value
        FROM public.promo_codes
       WHERE id = p_promo_code_id
         AND is_active = true
         AND (expires_at IS NULL OR expires_at > now())
         AND (max_uses    IS NULL OR uses_count < max_uses);

      IF FOUND THEN
        IF v_discount_type = 'percent' THEN
          v_final_price := v_final_price * (1 - v_discount_value / 100);
        ELSIF v_discount_type = 'fixed' THEN
          v_final_price := GREATEST(0, v_final_price - v_discount_value);
        END IF;

        UPDATE public.promo_codes
           SET uses_count = uses_count + 1
         WHERE id = p_promo_code_id;
      END IF;
    END;
  END IF;

  -- Insert booking row
  INSERT INTO public.bookings (
    artist_id,
    service_ids,
    service_names,
    start_time,
    end_time,
    total_duration_minutes,
    total_price,
    client_name,
    client_email,
    client_phone,
    promo_code_id,
    client_notes,
    status
  ) VALUES (
    p_artist_id,
    p_service_ids,
    p_service_names,
    p_start_time,
    v_end_time,
    p_total_duration,
    v_final_price,
    p_client_name,
    p_client_email,
    p_client_phone,
    p_promo_code_id,
    p_client_notes,
    p_initial_status
  )
  RETURNING * INTO v_booking;

  RETURN NEXT v_booking;
END;
$$;
