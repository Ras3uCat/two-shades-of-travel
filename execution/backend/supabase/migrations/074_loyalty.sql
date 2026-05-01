-- 074_loyalty.sql
-- Loyalty point ledger and business_config configuration columns.
-- Points are earned on completed bookings and redeemed at checkout.
-- All writes go through edge functions (service role); the policies below
-- only govern SELECT access for clients and admins.

-- ── Loyalty ledger ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.loyalty_ledger (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_email TEXT        NOT NULL,
  booking_id   UUID        REFERENCES public.bookings(id),
  points       INTEGER     NOT NULL,  -- positive = earned, negative = redeemed
  type         TEXT        NOT NULL CHECK (type IN ('earned', 'redeemed', 'expired', 'adjusted')),
  note         TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for the most common query: balance lookup by email
CREATE INDEX IF NOT EXISTS loyalty_ledger_email_idx
  ON public.loyalty_ledger (client_email);

ALTER TABLE public.loyalty_ledger ENABLE ROW LEVEL SECURITY;

-- Clients look up their own balance by supplying their email (unauthenticated flow).
-- A production tightening would add USING (client_email = auth.email()) for signed-in
-- clients; the permissive rule here supports the unauthenticated booking flow.
CREATE POLICY "client read own"
  ON public.loyalty_ledger
  FOR SELECT
  USING (true);

-- Admins can read all ledger rows for CRM / audit purposes
CREATE POLICY "admin read all loyalty"
  ON public.loyalty_ledger
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
       WHERE id = auth.uid() AND role IN ('master', 'staff')
    )
  );

-- Insert / update handled exclusively by edge functions via the service role key.

-- ── Loyalty configuration on business_config ─────────────────────────────────
ALTER TABLE public.business_config
  ADD COLUMN IF NOT EXISTS loyalty_enabled          BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS loyalty_points_per_dollar INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS loyalty_min_redeem        INTEGER NOT NULL DEFAULT 500,
  ADD COLUMN IF NOT EXISTS loyalty_cents_per_point   INTEGER NOT NULL DEFAULT 1;
