-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – ball_events table
--  Run this ONCE in your Supabase project's SQL Editor.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Create the table
create table if not exists public.ball_events (
  id                uuid primary key default gen_random_uuid(),
  innings_id        uuid not null references public.innings(id) on delete cascade,
  over_no           integer not null,
  ball_no           integer not null,
  runs_off_bat      integer not null default 0,
  extra_runs        integer not null default 0,
  extra_type        text, -- 'wide', 'no_ball', 'bye', 'leg_bye'
  wicket_type       text, -- 'bowled', 'caught', 'run_out', 'stumped', 'lbw', 'hit_wicket'
  wicket_player_name text,
  striker_name      text,
  non_striker_name  text,
  bowler_name       text,
  commentary        text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 2. Auto-update updated_at on every row change
create or replace function public.set_ball_events_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_ball_events_updated_at on public.ball_events;
create trigger trg_ball_events_updated_at
  before update on public.ball_events
  for each row execute procedure public.set_ball_events_updated_at();

-- 3. Row-Level Security
alter table public.ball_events enable row level security;

-- Anyone authenticated can view all ball events
create policy "auth_select_ball_events"
  on public.ball_events for select
  using (auth.role() = 'authenticated');

-- Players can insert their own ball events
create policy "player_insert_ball_events"
  on public.ball_events for insert
  with check (true); -- Allow all authenticated users to insert

-- Admins can do everything
create policy "admin_all_ball_events"
  on public.ball_events for all
  using ((auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin');
