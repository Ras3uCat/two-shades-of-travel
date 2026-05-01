-- 031_faq.sql — Frequently asked questions

create table if not exists public.faqs (
  id            uuid    primary key default gen_random_uuid(),
  question      text    not null,
  answer        text    not null,
  category      text,                          -- optional grouping (e.g. "Booking", "Payments")
  display_order int     not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

alter table public.faqs enable row level security;

-- Public: anyone can read active FAQs
create policy "Public can read active faqs"
  on public.faqs
  for select
  using (is_active = true);

-- Master can manage all rows
create policy "Master can manage faqs"
  on public.faqs
  for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'master'
    )
  );
