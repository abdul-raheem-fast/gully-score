-- Seed sample teams via `matches` so they appear in Discover & Apply.
-- Run this in Supabase SQL editor.

insert into public.matches (
  id,
  title,
  venue,
  match_date,
  overs_per_innings,
  toss_winner,
  toss_decision,
  team_a_name,
  team_b_name,
  status
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'Street Strikers vs Gully Giants',
    'National Stadium',
    current_date,
    10,
    'Street Strikers',
    'bat',
    'Street Strikers',
    'Gully Giants',
    'completed'
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'Power Hitters vs Boundary Kings',
    'City Ground',
    current_date,
    20,
    'Boundary Kings',
    'bowl',
    'Power Hitters',
    'Boundary Kings',
    'upcoming'
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'Yorker XI vs Spin Masters',
    'Lakeside Arena',
    current_date,
    10,
    'Yorker XI',
    'bat',
    'Yorker XI',
    'Spin Masters',
    'live'
  )
on conflict (id) do nothing;

-- Optional: create captain rows so captain approval panel can work.
-- Replace captain names with actual profile names of captain users.
insert into public.players (match_id, team_name, player_name, is_captain)
values
  ('11111111-1111-4111-8111-111111111111', 'Street Strikers', 'Captain Street', true),
  ('11111111-1111-4111-8111-111111111111', 'Gully Giants', 'Captain Gully', true),
  ('22222222-2222-4222-8222-222222222222', 'Power Hitters', 'Captain Power', true),
  ('22222222-2222-4222-8222-222222222222', 'Boundary Kings', 'Captain Boundary', true),
  ('33333333-3333-4333-8333-333333333333', 'Yorker XI', 'Captain Yorker', true),
  ('33333333-3333-4333-8333-333333333333', 'Spin Masters', 'Captain Spin', true);

-- Optional: mark a user's application as approved (replace values).
-- update public.team_memberships
-- set status = 'approved', updated_at = now()
-- where user_id = '<player-user-uuid>'::uuid
--   and team_name = 'Street Strikers';
