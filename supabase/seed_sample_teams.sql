-- Seed realistic PSL teams + squads for discover/apply and captain approvals.
-- Run this in Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  abbreviation text not null default '',
  captain_user_id uuid not null references auth.users(id) on delete cascade,
  captain_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.team_players (
  id uuid primary key default gen_random_uuid(),
  team_name text not null references public.teams(name)
    on update cascade on delete cascade,
  player_name text not null,
  is_captain boolean not null default false,
  joined_at timestamptz not null default now(),
  unique (team_name, player_name)
);

do $$
declare
  ahmad_user_id uuid;
  ahmad_name text;
  qg_user_id uuid;
  iu_user_id uuid;
  kk_user_id uuid;
  lq_user_id uuid;
  ms_user_id uuid;
  qg_name text;
  iu_name text;
  kk_name text;
  lq_name text;
  ms_name text;
begin
  select id, coalesce(name, split_part(email, '@', 1))
  into ahmad_user_id, ahmad_name
  from public.profiles
  where lower(email) = 'ahmad@gmail.com'
  limit 1;

  if ahmad_user_id is null then
    raise exception 'Profile not found for ahmad@gmail.com';
  end if;

  -- Try to attach captains to real users if they exist.
  select id, coalesce(name, split_part(email, '@', 1))
    into qg_user_id, qg_name
  from public.profiles where lower(email) = 'qg.captain@gmail.com' limit 1;
  select id, coalesce(name, split_part(email, '@', 1))
    into iu_user_id, iu_name
  from public.profiles where lower(email) = 'iu.captain@gmail.com' limit 1;
  select id, coalesce(name, split_part(email, '@', 1))
    into kk_user_id, kk_name
  from public.profiles where lower(email) = 'kk.captain@gmail.com' limit 1;
  select id, coalesce(name, split_part(email, '@', 1))
    into lq_user_id, lq_name
  from public.profiles where lower(email) = 'lq.captain@gmail.com' limit 1;
  select id, coalesce(name, split_part(email, '@', 1))
    into ms_user_id, ms_name
  from public.profiles where lower(email) = 'ms.captain@gmail.com' limit 1;

  qg_name := coalesce(qg_name, 'Sarfaraz Ahmed');
  iu_name := coalesce(iu_name, 'Shadab Khan');
  kk_name := coalesce(kk_name, 'Shan Masood');
  lq_name := coalesce(lq_name, 'Shaheen Afridi');
  ms_name := coalesce(ms_name, 'Mohammad Rizwan');

  insert into public.teams (name, abbreviation, captain_user_id, captain_name)
  values
    ('Peshawar Zalmi', 'PZ', ahmad_user_id, ahmad_name),
    ('Quetta Gladiators', 'QG', coalesce(qg_user_id, ahmad_user_id), qg_name),
    ('Islamabad United', 'IU', coalesce(iu_user_id, ahmad_user_id), iu_name),
    ('Karachi Kings', 'KK', coalesce(kk_user_id, ahmad_user_id), kk_name),
    ('Lahore Qalandars', 'LQ', coalesce(lq_user_id, ahmad_user_id), lq_name),
    ('Multan Sultans', 'MS', coalesce(ms_user_id, ahmad_user_id), ms_name)
  on conflict (name) do update
    set abbreviation = excluded.abbreviation,
        captain_user_id = excluded.captain_user_id,
        captain_name = excluded.captain_name,
        updated_at = now();

  -- 11-player squads (captain flagged in roster too).
  insert into public.team_players (team_name, player_name, is_captain) values
    ('Peshawar Zalmi', ahmad_name, true),
    ('Peshawar Zalmi', 'Saim Ayub', false),
    ('Peshawar Zalmi', 'Babar Azam', false),
    ('Peshawar Zalmi', 'Rovman Powell', false),
    ('Peshawar Zalmi', 'Tom Kohler-Cadmore', false),
    ('Peshawar Zalmi', 'Mohammad Haris', false),
    ('Peshawar Zalmi', 'Aamer Jamal', false),
    ('Peshawar Zalmi', 'Arif Yaqoob', false),
    ('Peshawar Zalmi', 'Luke Wood', false),
    ('Peshawar Zalmi', 'Naveen-ul-Haq', false),
    ('Peshawar Zalmi', 'Khurram Shahzad', false),

    ('Quetta Gladiators', qg_name, true),
    ('Quetta Gladiators', 'Jason Roy', false),
    ('Quetta Gladiators', 'Rilee Rossouw', false),
    ('Quetta Gladiators', 'Saud Shakeel', false),
    ('Quetta Gladiators', 'Sherfane Rutherford', false),
    ('Quetta Gladiators', 'Akeal Hosein', false),
    ('Quetta Gladiators', 'Mohammad Amir', false),
    ('Quetta Gladiators', 'Abrar Ahmed', false),
    ('Quetta Gladiators', 'Mohammad Wasim Jr', false),
    ('Quetta Gladiators', 'Sohail Khan', false),
    ('Quetta Gladiators', 'Sarfraz Nawaz Jr', false),

    ('Islamabad United', iu_name, true),
    ('Islamabad United', 'Colin Munro', false),
    ('Islamabad United', 'Alex Hales', false),
    ('Islamabad United', 'Azam Khan', false),
    ('Islamabad United', 'Faheem Ashraf', false),
    ('Islamabad United', 'Imad Wasim', false),
    ('Islamabad United', 'Naseem Shah', false),
    ('Islamabad United', 'Hunain Shah', false),
    ('Islamabad United', 'Tymal Mills', false),
    ('Islamabad United', 'Rumman Raees', false),
    ('Islamabad United', 'Salman Irshad', false),

    ('Karachi Kings', kk_name, true),
    ('Karachi Kings', 'James Vince', false),
    ('Karachi Kings', 'Kieron Pollard', false),
    ('Karachi Kings', 'Shoaib Malik', false),
    ('Karachi Kings', 'Tim Seifert', false),
    ('Karachi Kings', 'Irfan Khan Niazi', false),
    ('Karachi Kings', 'Mohammad Nawaz', false),
    ('Karachi Kings', 'Tabraiz Shamsi', false),
    ('Karachi Kings', 'Hasan Ali', false),
    ('Karachi Kings', 'Zahid Mahmood', false),
    ('Karachi Kings', 'Mir Hamza', false),

    ('Lahore Qalandars', lq_name, true),
    ('Lahore Qalandars', 'Fakhar Zaman', false),
    ('Lahore Qalandars', 'Abdullah Shafique', false),
    ('Lahore Qalandars', 'Rassie van der Dussen', false),
    ('Lahore Qalandars', 'Sikandar Raza', false),
    ('Lahore Qalandars', 'David Wiese', false),
    ('Lahore Qalandars', 'Haris Rauf', false),
    ('Lahore Qalandars', 'Zaman Khan', false),
    ('Lahore Qalandars', 'Jahandad Khan', false),
    ('Lahore Qalandars', 'Asif Afridi', false),
    ('Lahore Qalandars', 'Mohammad Imran', false),

    ('Multan Sultans', ms_name, true),
    ('Multan Sultans', 'Usman Khan', false),
    ('Multan Sultans', 'Iftikhar Ahmed', false),
    ('Multan Sultans', 'Khushdil Shah', false),
    ('Multan Sultans', 'Dawid Malan', false),
    ('Multan Sultans', 'Reeza Hendricks', false),
    ('Multan Sultans', 'Usama Mir', false),
    ('Multan Sultans', 'Mohammad Ali', false),
    ('Multan Sultans', 'Chris Jordan', false),
    ('Multan Sultans', 'David Willey', false),
    ('Multan Sultans', 'Shahnawaz Dahani', false)
  on conflict (team_name, player_name) do update
    set is_captain = excluded.is_captain;

  -- Add a completed match and sample scoring events so Ahmad shows real stats.
  insert into public.matches (
    id, title, venue, match_date, overs_per_innings, toss_winner, toss_decision,
    team_a_name, team_b_name, status
  )
  values (
    '44444444-4444-4444-8444-444444444444',
    'Peshawar Zalmi vs Quetta Gladiators',
    'Rawalpindi Cricket Stadium',
    current_date - interval '4 day',
    20,
    'Peshawar Zalmi',
    'bat',
    'Peshawar Zalmi',
    'Quetta Gladiators',
    'completed'
  )
  on conflict (id) do nothing;

  insert into public.players (match_id, team_name, player_name, is_captain) values
    ('44444444-4444-4444-8444-444444444444', 'Peshawar Zalmi', ahmad_name, true),
    ('44444444-4444-4444-8444-444444444444', 'Peshawar Zalmi', 'Saim Ayub', false),
    ('44444444-4444-4444-8444-444444444444', 'Quetta Gladiators', qg_name, true)
  on conflict do nothing;

  insert into public.innings (
    id, match_id, innings_no, batting_team, bowling_team, total_runs, wickets, balls_bowled, extras, is_completed
  )
  values
    ('55555555-5555-4555-8555-555555555551', '44444444-4444-4444-8444-444444444444', 1, 'Peshawar Zalmi', 'Quetta Gladiators', 162, 6, 120, 8, true),
    ('55555555-5555-4555-8555-555555555552', '44444444-4444-4444-8444-444444444444', 2, 'Quetta Gladiators', 'Peshawar Zalmi', 151, 8, 120, 10, true)
  on conflict (id) do update
    set total_runs = excluded.total_runs,
        wickets = excluded.wickets,
        balls_bowled = excluded.balls_bowled,
        extras = excluded.extras,
        is_completed = excluded.is_completed;

  insert into public.ball_events (
    innings_id, over_no, ball_no, striker_name, non_striker_name, bowler_name,
    runs_off_bat, extra_runs, extra_type, wicket_type, wicket_player_name, commentary
  )
  values
    ('55555555-5555-4555-8555-555555555551', 1, 1, ahmad_name, 'Saim Ayub', 'Mohammad Amir', 4, 0, null, null, null, 'Ahmad starts with a boundary.'),
    ('55555555-5555-4555-8555-555555555551', 1, 2, ahmad_name, 'Saim Ayub', 'Mohammad Amir', 2, 0, null, null, null, 'Punches into covers for two.'),
    ('55555555-5555-4555-8555-555555555551', 1, 3, ahmad_name, 'Saim Ayub', 'Mohammad Amir', 1, 0, null, null, null, 'Quick single taken.'),
    ('55555555-5555-4555-8555-555555555551', 2, 1, ahmad_name, 'Saim Ayub', 'Abrar Ahmed', 6, 0, null, null, null, 'Big six over long-on.'),
    ('55555555-5555-4555-8555-555555555551', 2, 2, ahmad_name, 'Saim Ayub', 'Abrar Ahmed', 3, 0, null, null, null, 'Placed into the gap for three.'),
    ('55555555-5555-4555-8555-555555555551', 2, 3, ahmad_name, 'Saim Ayub', 'Abrar Ahmed', 0, 0, null, 'caught', ahmad_name, 'Ahmad departs after a brisk start.'),
    ('55555555-5555-4555-8555-555555555552', 4, 4, 'Jason Roy', 'Rilee Rossouw', ahmad_name, 0, 0, null, 'bowled', 'Jason Roy', 'Ahmad cleans him up with a yorker.'),
    ('55555555-5555-4555-8555-555555555552', 8, 2, 'Saud Shakeel', 'Rilee Rossouw', ahmad_name, 1, 0, null, null, null, 'Tucked for one.'),
    ('55555555-5555-4555-8555-555555555552', 8, 3, 'Rilee Rossouw', 'Saud Shakeel', ahmad_name, 0, 0, null, 'caught', 'Rilee Rossouw', 'Taken at deep square leg.')
  on conflict do nothing;
end $$;
