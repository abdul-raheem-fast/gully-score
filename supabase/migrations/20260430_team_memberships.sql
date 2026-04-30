-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – team_memberships migration
--  Run this ONCE in your Supabase project's SQL Editor.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Create the table
create table if not exists public.team_memberships (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  team_name         text not null,
  team_abbreviation text not null default '',
  status            text not null default 'pending'
                      check (status in ('pending', 'approved', 'rejected')),
  applied_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  -- One row per (player, team). Re-applying updates the existing row.
  unique (user_id, team_name)
);

-- 2. Auto-update updated_at on every row change
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_team_memberships_updated_at on public.team_memberships;
create trigger trg_team_memberships_updated_at
  before update on public.team_memberships
  for each row execute procedure public.set_updated_at();

-- 3. Row-Level Security
alter table public.team_memberships enable row level security;

-- Players can read their own rows
create policy "player_select_own"
  on public.team_memberships for select
  using (auth.uid() = user_id);

-- Players can insert their own rows
create policy "player_insert_own"
  on public.team_memberships for insert
  with check (auth.uid() = user_id);

-- Players can update their own rows (e.g. re-apply after rejection)
create policy "player_update_own"
  on public.team_memberships for update
  using (auth.uid() = user_id);

-- Captains can read pending rows for teams they captain
-- (uses the players table to determine captaincy)
create policy "captain_select_team_requests"
  on public.team_memberships for select
  using (
    exists (
      select 1 from public.players p
      where p.team_name = team_memberships.team_name
        and p.is_captain = true
        and p.player_name = (
          select coalesce(raw_user_meta_data->>'name', email)
          from auth.users
          where id = auth.uid()
        )
    )
  );

-- Captains can approve or reject requests for their team
create policy "captain_update_team_requests"
  on public.team_memberships for update
  using (
    exists (
      select 1 from public.players p
      where p.team_name = team_memberships.team_name
        and p.is_captain = true
        and p.player_name = (
          select coalesce(raw_user_meta_data->>'name', email)
          from auth.users
          where id = auth.uid()
        )
    )
  );

-- Admins (app_role = 'admin' in JWT metadata) can do everything
create policy "admin_all"
  on public.team_memberships for all
  using (
    (auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin'
  );
