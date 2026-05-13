-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – Persistent Roster & Roles
-- ═══════════════════════════════════════════════════════════════════

-- 1. Add role column to team_players
alter table public.team_players 
add column if not exists role text check (role in ('Batsman', 'Bowler', 'All-rounder')) default 'Batsman';

-- 2. Enforce "One Player, One Team" 
-- We add a unique constraint on player_name. 
-- Note: This assumes player names are unique in your local league.
alter table public.team_players 
drop constraint if exists team_players_player_name_key;

alter table public.team_players 
add constraint team_players_player_name_key unique (player_name);

-- 3. Update team_memberships to also store role (for registered players)
alter table public.team_memberships 
add column if not exists role text check (role in ('Batsman', 'Bowler', 'All-rounder')) default 'Batsman';

-- 4. Function to get a team's saved roster
create or replace function public.get_team_roster(t_name text)
returns table (
  player_name text,
  role text,
  is_captain boolean
) 
language sql
security definer
as $$
  select player_name, role, is_captain
  from public.team_players
  where team_name = t_name;
$$;
