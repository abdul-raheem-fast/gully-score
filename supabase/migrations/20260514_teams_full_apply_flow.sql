-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – Full Team Application Flow
--  Run this in your Supabase project's SQL Editor.
--  Adds:
--    • player_name column on team_memberships (denormalized for captain view)
--    • notifications table (captain ← player apply / player ← decision)
--    • Fixes RLS so captains can update + read team_memberships via teams table
-- ═══════════════════════════════════════════════════════════════════

-- 1. Add player_name column to team_memberships (for captain panel enrichment)
alter table public.team_memberships
  add column if not exists player_name text not null default '';

-- 2. ── notifications table ────────────────────────────────────────
create table if not exists public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references auth.users(id) on delete cascade,
  sender_id     uuid references auth.users(id) on delete set null,
  type          text not null check (type in ('join_request', 'request_approved', 'request_rejected')),
  team_name     text not null default '',
  player_name   text not null default '',
  membership_id uuid references public.team_memberships(id) on delete cascade,
  is_read       boolean not null default false,
  created_at    timestamptz not null default now()
);

-- RLS for notifications
alter table public.notifications enable row level security;

-- Recipients can read their own notifications
create policy "notif_select_own"
  on public.notifications for select
  using (auth.uid() = recipient_id);

-- Anyone authenticated can insert a notification (applies → notifies captain)
create policy "notif_insert_auth"
  on public.notifications for insert
  with check (auth.role() = 'authenticated');

-- Recipients can mark notifications as read
create policy "notif_update_own"
  on public.notifications for update
  using (auth.uid() = recipient_id);

-- Admins can do everything
create policy "admin_all_notifications"
  on public.notifications for all
  using ((auth.jwt() -> 'user_metadata' ->> 'app_role') = 'admin');

-- 3. ── Extend team_memberships RLS to allow captains to update via `teams` table ──
-- Drop old policies first (idempotent)
drop policy if exists "captain_select_team_requests" on public.team_memberships;
drop policy if exists "captain_update_team_requests" on public.team_memberships;

create policy "captain_select_team_requests"
  on public.team_memberships for select
  using (
    -- Own rows
    auth.uid() = user_id
    -- Captain via players table (legacy)
    or exists (
      select 1 from public.players p
      where p.team_name = team_memberships.team_name
        and p.is_captain = true
        and p.player_name = (
          select coalesce(raw_user_meta_data->>'name', email)
          from auth.users
          where id = auth.uid()
        )
    )
    -- Captain via teams registry
    or exists (
      select 1 from public.teams t
      where t.name = team_memberships.team_name
        and t.captain_user_id = auth.uid()
    )
  );

create policy "captain_update_team_requests"
  on public.team_memberships for update
  using (
    -- Own rows (re-apply)
    auth.uid() = user_id
    -- Captain via players table (legacy)
    or exists (
      select 1 from public.players p
      where p.team_name = team_memberships.team_name
        and p.is_captain = true
        and p.player_name = (
          select coalesce(raw_user_meta_data->>'name', email)
          from auth.users
          where id = auth.uid()
        )
    )
    -- Captain via teams registry
    or exists (
      select 1 from public.teams t
      where t.name = team_memberships.team_name
        and t.captain_user_id = auth.uid()
    )
  );

-- 4. ── Index for fast notification lookup ─────────────────────────
create index if not exists idx_notifications_recipient on public.notifications(recipient_id, is_read, created_at desc);
create index if not exists idx_notifications_membership on public.notifications(membership_id);
create index if not exists idx_team_memberships_status on public.team_memberships(status, team_name);
