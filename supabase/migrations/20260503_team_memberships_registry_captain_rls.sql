-- Extend captain policies so `public.teams.captain_user_id` can approve join
-- requests (not only captains inferred from `public.players`).

drop policy if exists "captain_select_team_requests" on public.team_memberships;
drop policy if exists "captain_update_team_requests" on public.team_memberships;

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
    or exists (
      select 1 from public.teams t
      where t.name = team_memberships.team_name
        and t.captain_user_id = auth.uid()
    )
  );

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
    or exists (
      select 1 from public.teams t
      where t.name = team_memberships.team_name
        and t.captain_user_id = auth.uid()
    )
  );
