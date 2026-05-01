-- 092_push_subscriptions.sql
-- Web Push subscription storage for PWA push notifications (PUSH_ENABLED feature).
-- Supports both authenticated users (staff/master via user_id)
-- and guest clients (identified by client_email, no auth account required).

CREATE TABLE push_subscriptions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid REFERENCES auth.users ON DELETE CASCADE, -- nullable: staff/master only
  client_email text,                                         -- nullable: guest clients only
  endpoint     text NOT NULL UNIQUE,
  p256dh       text NOT NULL,
  auth_key     text NOT NULL,
  user_agent   text,
  created_at   timestamptz DEFAULT now(),
  CONSTRAINT identifier_required CHECK (user_id IS NOT NULL OR client_email IS NOT NULL)
);

ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- Authenticated users can manage their own subscription rows
CREATE POLICY "own subscriptions" ON push_subscriptions
  FOR ALL USING (auth.uid() = user_id);

-- Service role key (used by save-push-subscription and send-push) bypasses RLS automatically.
