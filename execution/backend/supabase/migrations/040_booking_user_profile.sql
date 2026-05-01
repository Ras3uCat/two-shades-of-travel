-- 040_booking_user_profile.sql
-- Adds client self-service RLS policies to the bookings table so that
-- authenticated users can read and cancel their own bookings.
-- Depends on: 010_booking.sql
-- Timestamped: 2026-03-06

-- Allow signed-in clients to read their own bookings (matched by email).
-- Stacks with the existing bookings_staff_read_own policy (OR semantics).
CREATE POLICY "bookings_client_read_own"
  ON bookings FOR SELECT
  USING (client_email = auth.email());

-- Allow clients to cancel their own future bookings (status → 'cancelled' only).
-- The USING clause guards the row; WITH CHECK enforces only 'cancelled' is writable.
CREATE POLICY "bookings_client_cancel"
  ON bookings FOR UPDATE
  USING (
    client_email = auth.email() AND
    start_time   > now()         AND
    status NOT IN ('cancelled', 'completed')
  )
  WITH CHECK (status = 'cancelled');
