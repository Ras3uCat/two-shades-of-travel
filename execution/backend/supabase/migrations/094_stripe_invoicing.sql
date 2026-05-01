-- 094_stripe_invoicing.sql
-- Adds Stripe invoice tracking to bookings (STRIPE_INVOICING_ENABLED feature).

ALTER TABLE bookings ADD COLUMN stripe_invoice_id  text;
ALTER TABLE bookings ADD COLUMN stripe_invoice_url  text;
ALTER TABLE bookings ADD COLUMN invoice_sent_at     timestamptz;
