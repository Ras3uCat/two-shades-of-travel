-- 030_testimonials.sql — Client testimonials / reviews

create table if not exists public.testimonials (
  id            uuid    primary key default gen_random_uuid(),
  author        text    not null,
  role          text,                          -- e.g. "Regular Client"
  quote         text    not null,
  rating        int     check (rating between 1 and 5),
  display_order int     not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

alter table public.testimonials enable row level security;

-- Public: anyone can read active testimonials
create policy "Public can read active testimonials"
  on public.testimonials
  for select
  using (is_active = true);

-- Master can manage all rows (insert / update / delete)
create policy "Master can manage testimonials"
  on public.testimonials
  for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'master'
    )
  );
