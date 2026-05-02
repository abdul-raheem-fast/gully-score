-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – teams & team_players tables
--  Run this ONCE in your Supabase project's SQL Editor.
-- ═══════════════════════════════════════════════════════════════════

-- 1. ── teams table ───────────────────────────────────────────────
create table if not exists public.teams (
  id               uuid primary key default gen_random_uuid(),
  name             text not null unique,
  abbreviation     text not null default '',
  captain_user_id  uuid not null references auth.users(id) on delete cascade,
  captain_name     text not null default '',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- 2. ── team_players table ────────────────────────────────────────
--    Stores the roster of each team (independent of matches).
create table if not exists public.team_players (
  id           uuid primary key default gen_random_uuid(),
  team_name    text not null references public.teams(name)
                 on update cascade on delete cascade,
  player_name  text not null,
  is_captain   boolean not null default false,
  joined_at    timestamptz not null default now(),
  unique (team_name, player_name)
);

-- 3. ── auto-update updated_at for teams ─────────────────────────
create or replace function public.set_teams_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_teams_updated_at on public.teams;
create trigger trg_teams_updated_at
  before update on public.teams
  for each row execute procedure public.set_teams_updated_at();

-- 4. ── Row-Level Security: teams ─────────────────────────────────
alter table public.teams enable row level security;

-- Anyone authenticated can view all teams
create policy "auth_select_teams"
  on public.teams for select
  using (auth.role() = 'authenticated');

-- Only the creator can insert their own team
create policy "auth_insert_own_team"
  on public.teams for insert
  with check (auth.uid() = captain_user_id);

-- Only the captain can update their team
create policy "captain_update_team"
  on public.teams for update
  using (auth.uid() = captain_user_id);

-- Captain can delete their team
create policy "captain_delete_team"
  on public.teams for delete
  using (auth.uid() = captain_user_id);

-- Admins can do everything
create policy "admin_all_teams"
  on public.teams for all
  using ((auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin');

-- 5. ── Row-Level Security: team_players ──────────────────────────
alter table public.team_players enable row level security;

-- Anyone authenticated can view team rosters
create policy "auth_select_team_players"
  on public.team_players for select
  using (auth.role() = 'authenticated');

-- Captains can manage their team's players
create policy "captain_manage_team_players"
  on public.team_players for all
  using (
    exists (
      select 1 from public.teams t
      where t.name = team_players.team_name
        and t.captain_user_id = auth.uid()
    )
  );

-- Admins can do everything
create policy "admin_all_team_players"
  on public.team_players for all
  using ((auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin');
