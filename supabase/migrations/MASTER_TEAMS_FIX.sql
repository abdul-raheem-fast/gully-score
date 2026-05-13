-- ═══════════════════════════════════════════════════════════════════
--  GULLY SCORE – MASTER TEAMS & NOTIFICATIONS SETUP
--  Run this in your Supabase SQL Editor to fix all missing table errors.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Create team_memberships table if missing
create table if not exists public.team_memberships (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  team_name         text not null,
  team_abbreviation text not null default '',
  player_name       text not null default '',
  status            text not null default 'pending',
  applied_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (user_id, team_name)
);

-- 2. Update status constraint to include 'invited'
alter table public.team_memberships drop constraint if exists team_memberships_status_check;
alter table public.team_memberships add constraint team_memberships_status_check 
  check (status in ('pending', 'approved', 'rejected', 'invited'));

-- 3. Create notifications table if missing
create table if not exists public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references auth.users(id) on delete cascade,
  sender_id     uuid references auth.users(id) on delete set null,
  type          text not null,
  team_name     text not null default '',
  player_name   text not null default '',
  membership_id uuid references public.team_memberships(id) on delete cascade,
  is_read       boolean not null default false,
  created_at    timestamptz not null default now()
);

-- 4. Enable RLS
alter table public.team_memberships enable row level security;
alter table public.notifications enable row level security;

-- 5. Team Memberships Policies
drop policy if exists "player_select_own" on public.team_memberships;
create policy "player_select_own" on public.team_memberships for select using (auth.uid() = user_id);

drop policy if exists "player_insert_own" on public.team_memberships;
create policy "player_insert_own" on public.team_memberships for insert with check (auth.uid() = user_id);

drop policy if exists "player_update_own" on public.team_memberships;
create policy "player_update_own" on public.team_memberships for update using (auth.uid() = user_id);

-- Captain policies (allows captains to manage their teams)
drop policy if exists "captain_manage_memberships" on public.team_memberships;
create policy "captain_manage_memberships" on public.team_memberships for all
using (
  exists (
    select 1 from public.teams t 
    where t.name = team_memberships.team_name 
    and t.captain_user_id = auth.uid()
  )
);

-- 6. Notifications Policies
drop policy if exists "notif_select_own" on public.notifications;
create policy "notif_select_own" on public.notifications for select using (auth.uid() = recipient_id);

drop policy if exists "notif_insert_all" on public.notifications;
create policy "notif_insert_all" on public.notifications for insert with check (true);

drop policy if exists "notif_update_own" on public.notifications;
create policy "notif_update_own" on public.notifications for update using (auth.uid() = recipient_id);

-- 7. Helper Function for Teamless Players
create or replace function public.get_teamless_players()
returns setof public.profiles
language sql
security definer
as $$
  select *
  from public.profiles
  where id not in (
    select user_id 
    from public.team_memberships 
    where status = 'approved'
  )
  and id != auth.uid();
$$;

-- 8. Updated At Trigger
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

-- 9. Cleanup old policies that might conflict
drop policy if exists "captain_select_team_requests" on public.team_memberships;
drop policy if exists "captain_update_team_requests" on public.team_memberships;
drop policy if exists "captains_can_invite" on public.team_memberships;
