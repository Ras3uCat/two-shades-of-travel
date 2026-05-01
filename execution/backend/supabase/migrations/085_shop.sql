-- 085_shop.sql
-- E-commerce module. Standalone — no booking dependency.
-- Public shop: /shop  Admin: /admin/shop/products + /admin/shop/orders
-- Stripe Checkout (payment mode) via create-shop-checkout edge function.
-- shop-webhook updates order status after payment confirmation.

-- ── Product categories ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  display_order INT  NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Products ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id            UUID REFERENCES product_categories(id) ON DELETE SET NULL,
  name                   TEXT NOT NULL,
  description            TEXT,
  price_cents            INT  NOT NULL CHECK (price_cents >= 0),
  compare_at_price_cents INT,           -- strikethrough "was" price
  images                 TEXT[] NOT NULL DEFAULT '{}',  -- storage public URLs
  inventory_count        INT,           -- NULL = unlimited
  is_active              BOOLEAN NOT NULL DEFAULT true,
  display_order          INT NOT NULL DEFAULT 0,
  tags                   TEXT[] NOT NULL DEFAULT '{}',
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_active   ON products (is_active, display_order);

-- ── Shop discount codes (separate from staff booking promo codes) ─────────────
CREATE TABLE IF NOT EXISTS shop_discount_codes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         TEXT NOT NULL UNIQUE,
  discount_pct INT  NOT NULL CHECK (discount_pct BETWEEN 1 AND 100),
  max_uses     INT,          -- NULL = unlimited
  used_count   INT NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  expires_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Orders ────────────────────────────────────────────────────────────────────
-- status: pending | paid | processing | shipped | delivered | cancelled | refunded
CREATE TABLE IF NOT EXISTS shop_orders (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_email          TEXT NOT NULL,
  client_name           TEXT NOT NULL,
  status                TEXT NOT NULL DEFAULT 'pending',
  stripe_session_id     TEXT,
  stripe_payment_intent TEXT,
  subtotal_cents        INT  NOT NULL DEFAULT 0,
  discount_cents        INT  NOT NULL DEFAULT 0,
  total_cents           INT  NOT NULL DEFAULT 0,
  discount_code         TEXT REFERENCES shop_discount_codes(code) ON DELETE SET NULL,
  gift_voucher_code     TEXT,  -- validated on checkout; see gift_vouchers table
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shop_orders_email   ON shop_orders (client_email);
CREATE INDEX IF NOT EXISTS idx_shop_orders_status  ON shop_orders (status);
CREATE INDEX IF NOT EXISTS idx_shop_orders_session ON shop_orders (stripe_session_id);

-- ── Order items ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shop_order_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     UUID NOT NULL REFERENCES shop_orders(id) ON DELETE CASCADE,
  product_id   UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,   -- snapshot at purchase time
  price_cents  INT  NOT NULL,   -- snapshot
  quantity     INT  NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shop_order_items_order ON shop_order_items (order_id);

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products            ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_discount_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_orders         ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_order_items    ENABLE ROW LEVEL SECURITY;

-- Public: read active products and all categories
CREATE POLICY "public_read_active_products"
  ON products FOR SELECT USING (is_active = true);

CREATE POLICY "public_read_categories"
  ON product_categories FOR SELECT USING (true);

-- Master: full access
CREATE POLICY "master_all_products"
  ON products FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

CREATE POLICY "master_all_categories"
  ON product_categories FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

CREATE POLICY "master_all_discount_codes"
  ON shop_discount_codes FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

CREATE POLICY "master_all_shop_orders"
  ON shop_orders FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

CREATE POLICY "master_all_shop_order_items"
  ON shop_order_items FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

-- Clients: read their own orders by email
CREATE POLICY "client_read_own_orders"
  ON shop_orders FOR SELECT
  USING (client_email = (SELECT email FROM auth.users WHERE id = auth.uid()));

CREATE POLICY "client_read_own_order_items"
  ON shop_order_items FOR SELECT
  USING (
    order_id IN (
      SELECT id FROM shop_orders
      WHERE client_email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- ── Trigger: updated_at ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_product_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_product_timestamp();

-- ── validate_shop_discount(code) ──────────────────────────────────────────────
-- Returns discount_pct if the code is valid, else 0.
-- Called from create-shop-checkout edge function.
CREATE OR REPLACE FUNCTION validate_shop_discount(p_code TEXT)
RETURNS INT
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE v_pct INT;
BEGIN
  SELECT discount_pct INTO v_pct
  FROM shop_discount_codes
  WHERE code      = p_code
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > now())
    AND (max_uses  IS NULL OR used_count < max_uses);
  RETURN COALESCE(v_pct, 0);
END;
$$;

-- ── decrement_product_inventory(product_id, qty) ──────────────────────────────
-- Called by shop-webhook after payment confirms. No-op if inventory is unlimited (NULL).
CREATE OR REPLACE FUNCTION decrement_product_inventory(p_product_id UUID, p_qty INT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE products
  SET inventory_count = GREATEST(0, inventory_count - p_qty)
  WHERE id = p_product_id AND inventory_count IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION decrement_product_inventory(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION decrement_product_inventory(UUID, INT) TO service_role;

-- ── increment_discount_used_count(code) ───────────────────────────────────────
-- Called by shop-webhook after payment confirms. Increments used_count by 1.
CREATE OR REPLACE FUNCTION increment_discount_used_count(p_code TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE shop_discount_codes SET used_count = used_count + 1 WHERE code = p_code;
END;
$$;

REVOKE ALL ON FUNCTION increment_discount_used_count(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_discount_used_count(TEXT) TO service_role;
