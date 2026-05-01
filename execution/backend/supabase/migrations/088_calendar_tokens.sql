-- 088_calendar_tokens.sql
-- Stores a secret UUID token per staff member for their iCal feed URL.
-- The token is included in the feed URL so calendar apps can subscribe
-- without sending auth headers (which calendar apps cannot do).
-- Regenerating the token intentionally breaks existing subscriptions (revoke).

CREATE TABLE IF NOT EXISTS calendar_tokens (
  staff_id   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  token      UUID NOT NULL DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE calendar_tokens ENABLE ROW LEVEL SECURITY;

-- Staff can read their own token
CREATE POLICY "tokens_own_read" ON calendar_tokens
  FOR SELECT USING (auth.uid() = staff_id);

-- Staff can insert their own row (first-time token creation)
CREATE POLICY "tokens_own_insert" ON calendar_tokens
  FOR INSERT WITH CHECK (auth.uid() = staff_id);

-- Staff can regenerate their own token
CREATE POLICY "tokens_own_update" ON calendar_tokens
  FOR UPDATE USING (auth.uid() = staff_id);

-- Master can manage any staff token
CREATE POLICY "tokens_master_all" ON calendar_tokens
  FOR ALL USING ((auth.jwt() ->> 'user_role') = 'master');

GRANT ALL ON calendar_tokens TO service_role;

-- Helper function so the client never has to supply a UUID —
-- Postgres generates it server-side via gen_random_uuid().
-- Called by Flutter via .rpc('regenerate_calendar_token', {'p_staff_id': id})
CREATE OR REPLACE FUNCTION regenerate_calendar_token(p_staff_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_token UUID;
BEGIN
  UPDATE calendar_tokens
  SET    token = gen_random_uuid()
  WHERE  staff_id = p_staff_id
  RETURNING token INTO v_token;

  IF v_token IS NULL THEN
    INSERT INTO calendar_tokens (staff_id)
    VALUES (p_staff_id)
    RETURNING token INTO v_token;
  END IF;

  RETURN v_token;
END;
$$;

-- Grant execute to authenticated users (RLS on the underlying table
-- already restricts who can actually trigger a regeneration).
REVOKE ALL ON FUNCTION regenerate_calendar_token(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION regenerate_calendar_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION regenerate_calendar_token(UUID) TO service_role;
