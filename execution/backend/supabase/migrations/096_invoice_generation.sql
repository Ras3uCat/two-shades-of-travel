-- 096_invoice_generation.sql
-- PDF invoice generation — sequential invoice numbers (INVOICES_ENABLED feature).

ALTER TABLE bookings ADD COLUMN invoice_number text;

CREATE SEQUENCE IF NOT EXISTS invoice_seq START 1000;

CREATE OR REPLACE FUNCTION next_invoice_number()
RETURNS text LANGUAGE sql AS $$
  SELECT 'INV-' || LPAD(nextval('invoice_seq')::text, 5, '0')
$$;
