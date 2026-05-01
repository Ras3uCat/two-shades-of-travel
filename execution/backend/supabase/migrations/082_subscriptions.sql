-- 082_subscriptions.sql
-- Subscription plans + subscriber registry.
--
-- Subscriptions are INDEPENDENT of the booking module. A subscription plan
-- can represent a membership, class pass, product box, retainer, or anything
-- the client decides. The booking_discount_pct and included_service_ids fields
-- are optional hooks that can be used if the client also has booking enabled.
--
-- stripe_price_id is intentionally nullable — the client creates the product
-- and price in their Stripe dashboard first, then pastes the Price ID here.

CREATE TABLE IF NOT EXISTS subscription_plans (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT    NOT NULL,
  description           TEXT,
  price_cents           INT     NOT NULL CHECK (price_cents >= 0),
  interval_type         TEXT    NOT NULL DEFAULT 'monthly'
                          CHECK (interval_type IN ('monthly', 'quarterly', 'yearly')),
  stripe_price_id       TEXT,                          -- set after Stripe product creation
  -- Optional booking integration (only relevant if booking module also enabled)
  booking_discount_pct  INT     NOT NULL DEFAULT 0
                          CHECK (booking_discount_pct BETWEEN 0 AND 100),
  included_service_ids  TEXT[]  NOT NULL DEFAULT '{}', -- free per-interval services
  -- Human-readable bullet points for the public plan card
  features              TEXT[]  NOT NULL DEFAULT '{}',
  is_active             BOOLEAN NOT NULL DEFAULT TRUE,
  display_order         INT     NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id                 UUID    NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
  client_email            TEXT    NOT NULL,
  client_name             TEXT    NOT NULL,
  stripe_subscription_id  TEXT,          -- null for manual / offline subscriptions
  stripe_customer_id      TEXT,
  status                  TEXT    NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active','trialing','past_due','cancelled')),
  current_period_start    TIMESTAMPTZ,
  current_period_end      TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at            TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_email  ON subscriptions (client_email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions (status);

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions       ENABLE ROW LEVEL SECURITY;

-- Plans: anyone can read active plans; master has full access
CREATE POLICY "public_read_active_plans"
  ON subscription_plans FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "master_all_plans"
  ON subscription_plans FOR ALL
  USING  ((auth.jwt() ->> 'user_role') IN ('master'))
  WITH CHECK ((auth.jwt() ->> 'user_role') IN ('master'));

-- Subscriptions: master full access; client reads their own
CREATE POLICY "master_all_subscriptions"
  ON subscriptions FOR ALL
  USING  ((auth.jwt() ->> 'user_role') IN ('master'))
  WITH CHECK ((auth.jwt() ->> 'user_role') IN ('master'));

CREATE POLICY "client_read_own_subscription"
  ON subscriptions FOR SELECT
  USING (client_email = (auth.jwt() ->> 'email'));
