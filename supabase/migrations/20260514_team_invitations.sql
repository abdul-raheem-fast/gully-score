-- ═══════════════════════════════════════════════════════════════════
--  GullyScore – Team Creation & Invitation System
-- ═══════════════════════════════════════════════════════════════════

-- 1. Ensure 'invited' is a valid status (if you have a check constraint)
-- If your 'status' column has a check constraint, we need to allow 'invited'.
-- Most common way to check current constraint:
-- SELECT consrc FROM pg_constraint WHERE conrelid = 'public.team_memberships'::regclass AND contype = 'c';

-- For safety, we'll just ensure the logic works. 
-- We'll also add a 'sender_id' to notifications to track who invited whom if not already there.

-- 2. Create a helper function to find players not in any team
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
  and id != auth.uid(); -- Don't show myself
$$;

-- 3. Update RLS to allow captains to insert invitations
create policy "captains_can_invite"
  on public.team_memberships for insert
  with check (
    exists (
      select 1 from public.teams
      where name = team_name
      and captain_user_id = auth.uid()
    )
  );
