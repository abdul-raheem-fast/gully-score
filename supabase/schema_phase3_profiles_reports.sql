-- Phase 3 schema for auth-linked profiles and moderation reports.
-- Run this once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text not null,
  role text not null check (role in ('admin', 'player')),
  phone text,
  playing_role text,
  organization text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete set null,
  title text not null,
  description text not null,
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high')),
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_reports_match_id on public.reports(match_id);
create index if not exists idx_reports_status on public.reports(status);

alter table public.profiles enable row level security;
alter table public.reports enable row level security;

drop policy if exists "profiles self read" on public.profiles;
create policy "profiles self read"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "profiles self upsert" on public.profiles;
create policy "profiles self upsert"
on public.profiles
for all
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "reports read authenticated" on public.reports;
create policy "reports read authenticated"
on public.reports
for select
to authenticated
using (true);

drop policy if exists "reports create authenticated" on public.reports;
create policy "reports create authenticated"
on public.reports
for insert
to authenticated
with check (auth.uid() = created_by or created_by is null);

drop policy if exists "reports update authenticated" on public.reports;
create policy "reports update authenticated"
on public.reports
for update
to authenticated
using (true)
with check (true);
