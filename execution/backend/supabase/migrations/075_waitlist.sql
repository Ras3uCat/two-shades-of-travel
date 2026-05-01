-- 075_waitlist.sql
-- Waitlist table: clients join when no slots are available.
-- On booking cancellation, the edge function notifies all unnotified entries
-- for the affected artist and marks them notified_at = now().

CREATE TABLE IF NOT EXISTS waitlist (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id       uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  service_ids     text[] NOT NULL DEFAULT '{}',
  preferred_date  date,           -- informational only, not used for matching
  client_name     text NOT NULL,
  client_email    text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  notified_at     timestamptz     -- null = not yet notified
);

CREATE INDEX IF NOT EXISTS waitlist_artist_idx ON waitlist (artist_id) WHERE notified_at IS NULL;

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Public can join (unauthenticated booking flow)
CREATE POLICY "waitlist_public_insert" ON waitlist
  FOR INSERT WITH CHECK (true);

-- Admin/master can read and update (mark notified, view list)
CREATE POLICY "waitlist_admin_all" ON waitlist
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('master', 'staff'))
  );
