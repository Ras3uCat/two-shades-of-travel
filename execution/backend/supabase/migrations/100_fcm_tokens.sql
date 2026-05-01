-- 100_fcm_tokens.sql
-- Adds FCM token support to push_subscriptions for native iOS/Android push.
-- Web Push columns made nullable — FCM rows don't have endpoint/p256dh/auth_key.
-- Applied when FCM_ENABLED=true (see setup.sh).
--
-- NOTE: endpoint UNIQUE constraint is intentionally kept intact.
-- PostgreSQL allows multiple NULLs in a UNIQUE column (NULL != NULL),
-- so FCM rows (endpoint IS NULL) don't conflict with each other.
-- Supabase upsert onConflict:'endpoint' continues to work for Web Push rows.

-- Make Web Push fields nullable (FCM subscriptions have no endpoint/keys)
ALTER TABLE push_subscriptions
  ALTER COLUMN endpoint  DROP NOT NULL,
  ALTER COLUMN p256dh    DROP NOT NULL,
  ALTER COLUMN auth_key  DROP NOT NULL;

-- FCM token — unique per device registration
ALTER TABLE push_subscriptions
  ADD COLUMN IF NOT EXISTS fcm_token text UNIQUE;
