-- 087_events.sql
-- Events module. Standalone — no booking dependency.
-- Public: /events  /events/:slug  Admin: /admin/events  /admin/events/:id/attendees
-- Stripe Checkout (payment mode) via create-event-checkout edge function.
-- event-webhook updates ticket status after payment confirmation.
-- cancel-event issues Stripe refunds + marks all tickets cancelled.

-- ── Events ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title          TEXT        NOT NULL,
  slug           TEXT        NOT NULL UNIQUE,
  description    TEXT,
  event_date     TIMESTAMPTZ NOT NULL,
  venue          TEXT,
  hero_image_url TEXT,
  capacity       INT         NOT NULL CHECK (capacity > 0),
  status         TEXT        NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft', 'published', 'cancelled')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_status ON events (status, event_date);
CREATE INDEX IF NOT EXISTS idx_events_slug   ON events (slug);

-- ── Event ticket types ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS event_ticket_types (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id       UUID        NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  name           TEXT        NOT NULL,
  description    TEXT,
  price_cents    INT         NOT NULL CHECK (price_cents >= 0),
  quantity_total INT         NOT NULL CHECK (quantity_total > 0),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ticket_types_event ON event_ticket_types (event_id);

-- ── Event tickets (purchased) ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS event_tickets (
  id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id               UUID        NOT NULL REFERENCES events(id)              ON DELETE RESTRICT,
  ticket_type_id         UUID        NOT NULL REFERENCES event_ticket_types(id)  ON DELETE RESTRICT,
  buyer_name             TEXT        NOT NULL,
  buyer_email            TEXT        NOT NULL,
  quantity               INT         NOT NULL DEFAULT 1 CHECK (quantity > 0),
  total_cents            INT         NOT NULL CHECK (total_cents >= 0),
  ticket_code            UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  stripe_session_id      TEXT,
  stripe_payment_intent  TEXT,
  stripe_refund_id       TEXT,
  status                 TEXT        NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'confirmed', 'cancelled', 'checked_in')),
  checked_in_at          TIMESTAMPTZ,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_tickets_event   ON event_tickets (event_id, status);
CREATE INDEX IF NOT EXISTS idx_event_tickets_email   ON event_tickets (buyer_email);
CREATE INDEX IF NOT EXISTS idx_event_tickets_session ON event_tickets (stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_event_tickets_code    ON event_tickets (ticket_code);

-- ── updated_at triggers ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION _events_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS events_updated_at       ON events;
DROP TRIGGER IF EXISTS event_tickets_updated_at ON event_tickets;

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION _events_set_updated_at();

CREATE TRIGGER event_tickets_updated_at
  BEFORE UPDATE ON event_tickets
  FOR EACH ROW EXECUTE FUNCTION _events_set_updated_at();

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE events             ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_tickets      ENABLE ROW LEVEL SECURITY;

-- events: public reads published; master manages all
DROP POLICY IF EXISTS "events_public_read"  ON events;
DROP POLICY IF EXISTS "events_master_all"   ON events;

CREATE POLICY "events_public_read"
  ON events FOR SELECT
  USING (status = 'published');

CREATE POLICY "events_master_all"
  ON events FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

-- event_ticket_types: public reads types for published events; master manages all
DROP POLICY IF EXISTS "ticket_types_public_read" ON event_ticket_types;
DROP POLICY IF EXISTS "ticket_types_master_all"  ON event_ticket_types;

CREATE POLICY "ticket_types_public_read"
  ON event_ticket_types FOR SELECT
  USING (
    event_id IN (SELECT id FROM events WHERE status = 'published')
  );

CREATE POLICY "ticket_types_master_all"
  ON event_ticket_types FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

-- event_tickets: anonymous INSERT (guest purchase); master manages all
-- Buyers cannot read their own tickets via client — confirmation comes via email + in-app arguments
DROP POLICY IF EXISTS "event_tickets_public_insert" ON event_tickets;
DROP POLICY IF EXISTS "event_tickets_master_all"    ON event_tickets;

CREATE POLICY "event_tickets_public_insert"
  ON event_tickets FOR INSERT
  WITH CHECK (true);

CREATE POLICY "event_tickets_master_all"
  ON event_tickets FOR ALL
  USING  ((auth.jwt() ->> 'user_role') = 'master')
  WITH CHECK ((auth.jwt() ->> 'user_role') = 'master');

-- ── purchase_event_tickets() ──────────────────────────────────────────────────
-- Row-locked atomic purchase. Called only by Edge Functions via service_role.
-- Raises named exceptions on failure: TICKET_TYPE_NOT_FOUND, EVENT_NOT_AVAILABLE, SOLD_OUT.
CREATE OR REPLACE FUNCTION purchase_event_tickets(
  p_event_id       UUID,
  p_ticket_type_id UUID,
  p_quantity       INT,
  p_buyer_email    TEXT,
  p_buyer_name     TEXT,
  p_initial_status TEXT DEFAULT 'pending'
)
RETURNS event_tickets
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
AS $$
DECLARE
  v_type   event_ticket_types%ROWTYPE;
  v_event  events%ROWTYPE;
  v_sold   INT;
  v_avail  INT;
  v_total  INT;
  v_ticket event_tickets%ROWTYPE;
BEGIN
  -- Lock the ticket type row to serialise concurrent purchases
  SELECT * INTO v_type
  FROM event_ticket_types
  WHERE id = p_ticket_type_id AND event_id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TICKET_TYPE_NOT_FOUND';
  END IF;

  SELECT * INTO v_event FROM events WHERE id = p_event_id;

  IF v_event.status <> 'published' THEN
    RAISE EXCEPTION 'EVENT_NOT_AVAILABLE';
  END IF;

  -- Count sold (pending holds a slot; cancelled does not)
  SELECT COALESCE(SUM(quantity), 0) INTO v_sold
  FROM event_tickets
  WHERE ticket_type_id = p_ticket_type_id
    AND status NOT IN ('cancelled');

  v_avail := v_type.quantity_total - v_sold;

  IF v_avail < p_quantity THEN
    RAISE EXCEPTION 'SOLD_OUT: % remaining', v_avail;
  END IF;

  v_total := v_type.price_cents * p_quantity;

  INSERT INTO event_tickets (
    event_id, ticket_type_id, buyer_name, buyer_email,
    quantity, total_cents, status
  ) VALUES (
    p_event_id, p_ticket_type_id, p_buyer_name, p_buyer_email,
    p_quantity, v_total, p_initial_status
  )
  RETURNING * INTO v_ticket;

  RETURN v_ticket;
END;
$$;

REVOKE ALL ON FUNCTION purchase_event_tickets(UUID,UUID,INT,TEXT,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION purchase_event_tickets(UUID,UUID,INT,TEXT,TEXT,TEXT) TO service_role;

-- ── get_ticket_availability() ─────────────────────────────────────────────────
-- Returns remaining quantity per ticket type for a given event.
-- Public read — no auth required.
CREATE OR REPLACE FUNCTION get_ticket_availability(p_event_id UUID)
RETURNS TABLE (
  ticket_type_id UUID,
  quantity_total INT,
  quantity_sold  INT,
  quantity_avail INT
)
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT
    tt.id                                                      AS ticket_type_id,
    tt.quantity_total,
    COALESCE(SUM(t.quantity), 0)::INT                          AS quantity_sold,
    (tt.quantity_total - COALESCE(SUM(t.quantity), 0))::INT    AS quantity_avail
  FROM event_ticket_types tt
  LEFT JOIN event_tickets t
    ON t.ticket_type_id = tt.id
   AND t.status NOT IN ('cancelled')
  WHERE tt.event_id = p_event_id
  GROUP BY tt.id, tt.quantity_total;
$$;

GRANT EXECUTE ON FUNCTION get_ticket_availability(UUID) TO anon, authenticated;

-- ── cancel_event_tickets() ────────────────────────────────────────────────────
-- Marks all non-cancelled tickets for an event as cancelled.
-- Returns payment intents so the Edge Function can issue Stripe refunds.
-- Called only by Edge Functions via service_role.
CREATE OR REPLACE FUNCTION cancel_event_tickets(p_event_id UUID)
RETURNS TABLE (
  ticket_id             UUID,
  stripe_payment_intent TEXT,
  total_cents           INT
)
LANGUAGE sql VOLATILE SECURITY DEFINER
AS $$
  UPDATE event_tickets
  SET status = 'cancelled', updated_at = now()
  WHERE event_id = p_event_id
    AND status NOT IN ('cancelled')
  RETURNING id, stripe_payment_intent, total_cents;
$$;

REVOKE ALL ON FUNCTION cancel_event_tickets(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION cancel_event_tickets(UUID) TO service_role;
