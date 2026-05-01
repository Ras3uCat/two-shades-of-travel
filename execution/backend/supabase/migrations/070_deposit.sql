-- 070_deposit.sql
-- Adds deposit_pct to business_config to control payment collection at booking time.
-- 0   = no payment required at booking (book now, pay at appointment).
-- 1–99 = partial deposit charged now; remainder shown as "BALANCE AT APPOINTMENT".
-- 100 = full amount charged at booking (default — standard Stripe checkout behaviour).
-- Configure in Admin → Settings → Booking Rules.

ALTER TABLE public.business_config
  ADD COLUMN IF NOT EXISTS deposit_pct INTEGER NOT NULL DEFAULT 100
    CHECK (deposit_pct BETWEEN 0 AND 100);
