-- 091_tip.sql
-- Adds tip_amount to bookings for gratuity at checkout (TIP_ENABLED feature)

ALTER TABLE bookings ADD COLUMN tip_amount integer NOT NULL DEFAULT 0; -- cents
