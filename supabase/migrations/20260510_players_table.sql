-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – players table
--  Run this ONCE in your Supabase project's SQL Editor.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Create the table
create table if not exists public.players (
  id                uuid primary key default gen_random_uuid(),
  match_id          uuid not null references public.matches(id) on delete cascade,
  team_name         text not null,
  player_name       text not null,
  is_captain        boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 2. Auto-update updated_at on every row change
create or replace function public.set_players_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_players_updated_at on public.players;
create trigger trg_players_updated_at
  before update on public.players
  for each row execute procedure public.set_players_updated_at();

-- 3. Row-Level Security
alter table public.players enable row level security;

-- Anyone authenticated can view all players
create policy "auth_select_players"
  on public.players for select
  using (auth.role() = 'authenticated');

-- Players can insert their own rows
create policy "player_insert_own"
  on public.players for insert
  with check (true); -- Allow all authenticated users to insert

-- Captains can manage their team's players
create policy "captain_manage_players"
  on public.players for all
  using (
    exists (
      select 1 from public.teams t
      where t.name = players.team_name
        and t.captain_user_id = auth.uid()
    )
  );

-- Admins can do everything
create policy "admin_all_players"
  on public.players for all
  using ((auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin');
