-- 072_gift_vouchers.sql
-- Introduces the gift_vouchers table and links it to bookings.
-- Also adds loyalty_points_redeemed to bookings (used by 074_loyalty.sql).
-- Redemption writes are handled by edge functions running as the service role;
-- no INSERT/UPDATE policy is needed for the anon/authenticated roles here.

CREATE TABLE IF NOT EXISTS public.gift_vouchers (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code                     TEXT        UNIQUE NOT NULL,
  amount_cents             INTEGER     NOT NULL CHECK (amount_cents > 0),
  purchased_by_email       TEXT        NOT NULL,
  recipient_email          TEXT        NOT NULL,
  message                  TEXT,
  stripe_payment_intent_id TEXT,
  redeemed_at              TIMESTAMPTZ,
  redeemed_by_booking_id   UUID        REFERENCES public.bookings(id),
  expires_at               TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '12 months'),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.gift_vouchers ENABLE ROW LEVEL SECURITY;

-- Public can look up a voucher by code (needed for unauthenticated booking flow)
CREATE POLICY "public read gift vouchers"
  ON public.gift_vouchers
  FOR SELECT
  USING (true);

-- Insert / update handled exclusively by edge functions via the service role key.
-- No anon/authenticated INSERT or UPDATE policy is intentionally defined here.

-- Link bookings → gift_vouchers (nullable — most bookings won't use a voucher)
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS gift_voucher_id UUID REFERENCES public.gift_vouchers(id);

-- Loyalty points redeemed at booking time (populated by loyalty edge function)
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS loyalty_points_redeemed INTEGER NOT NULL DEFAULT 0;
