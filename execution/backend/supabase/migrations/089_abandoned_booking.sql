-- 089_abandoned_booking.sql
-- Adds recovery_email_sent flag to bookings for abandoned checkout recovery.
-- Used by send-abandoned-recovery Edge Function to prevent duplicate emails.

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS recovery_email_sent BOOLEAN NOT NULL DEFAULT FALSE;

-- Partial index — only pending rows are queried for recovery
CREATE INDEX IF NOT EXISTS idx_bookings_abandoned
  ON bookings (created_at)
  WHERE status = 'pending' AND recovery_email_sent = FALSE;
