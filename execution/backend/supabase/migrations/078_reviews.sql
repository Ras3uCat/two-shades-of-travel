-- 078_reviews.sql
-- Client reviews: token-authenticated submission, admin approval gate.
-- review_token is generated at booking creation and sent via edge function.
-- Timestamped: 2026-03-06

-- ─── Add review_token to bookings ─────────────────────────────────────────────
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS review_token uuid DEFAULT gen_random_uuid();

-- ─── Reviews table ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   uuid        NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  client_email text        NOT NULL,
  client_name  text        NOT NULL,
  rating       integer     NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      text,
  is_approved  boolean     NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS reviews_booking_id_idx ON reviews(booking_id);
CREATE INDEX IF NOT EXISTS reviews_approved_idx   ON reviews(is_approved);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Public insert: token validation is handled server-side in the submit-review edge function
CREATE POLICY "reviews_public_insert"
  ON reviews FOR INSERT
  WITH CHECK (true);

-- Public read: approved reviews only
CREATE POLICY "reviews_public_select"
  ON reviews FOR SELECT
  USING (is_approved = true);

-- Admin full control (approve, delete, edit)
CREATE POLICY "reviews_admin_all"
  ON reviews FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('master', 'staff'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('master', 'staff'))
  );
