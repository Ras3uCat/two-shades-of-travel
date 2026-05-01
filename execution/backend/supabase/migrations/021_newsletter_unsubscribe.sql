-- 021_newsletter_unsubscribe.sql
-- Adds a unique unsubscribe token to every subscriber row.
-- The token is included in welcome emails and validated by the unsubscribe Edge Function.

ALTER TABLE public.subscribers
  ADD COLUMN IF NOT EXISTS unsubscribe_token UUID NOT NULL DEFAULT gen_random_uuid();

CREATE UNIQUE INDEX IF NOT EXISTS subscribers_unsubscribe_token_idx
  ON public.subscribers (unsubscribe_token);
