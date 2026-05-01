-- 020_newsletter.sql — Newsletter subscribers
-- Tracks email subscriptions; welcome email sent via send-welcome Edge Function.

create table if not exists public.subscribers (
  id            uuid        primary key default gen_random_uuid(),
  email         text        not null unique,
  name          text,
  source        text        not null default 'website',
  is_active     boolean     not null default true,
  subscribed_at timestamptz not null default now()
);

alter table public.subscribers enable row level security;

-- Anyone (anon or auth) can subscribe
create policy "Anyone can subscribe"
  on public.subscribers
  for insert
  to anon, authenticated
  with check (true);

-- No public reads — subscriber list stays private
-- Service role (Edge Functions) reads/manages via service key, bypasses RLS
