-- 079_client_photos.sql
-- Before/after private photo gallery scoped to individual bookings.
-- Photos are stored in Supabase Storage under the 'client-photos' bucket.
--
-- IMPORTANT: Create the 'client-photos' Storage bucket manually in the Supabase
-- dashboard (Storage → New bucket). Set it to PRIVATE (not public). RLS on this
-- table controls which authenticated users can read paths; Storage bucket policies
-- should restrict direct object access to the service role only (edge functions
-- serve signed URLs on demand).
--
-- Timestamped: 2026-03-06

-- ─── client_photos table ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS client_photos (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   uuid        NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  storage_path text        NOT NULL,  -- path within 'client-photos' bucket
  is_before    boolean     NOT NULL DEFAULT false,  -- true = before, false = after
  uploaded_by  uuid        NOT NULL REFERENCES profiles(id),  -- must be master role
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS client_photos_booking_id_idx ON client_photos(booking_id);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE client_photos ENABLE ROW LEVEL SECURITY;

-- Master can insert, update, and delete
CREATE POLICY "client_photos_master_write"
  ON client_photos FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'master')
  );

-- Client can read photos for their own bookings (matched by JWT email claim)
CREATE POLICY "client_photos_client_read"
  ON client_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.id = booking_id
        AND b.client_email = auth.jwt() ->> 'email'
    )
  );
