-- Delhi Dino backend: run this once in Supabase → SQL Editor → New query → Run.
-- Safe to re-run: it drops and recreates only the objects it owns.

-- ---------- profiles: one per signed-in player ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 24),
  country char(2) not null check (country ~ '^[A-Z]{2}$'),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles are public" on public.profiles;
drop policy if exists "update own profile" on public.profiles;
create policy "profiles are public" on public.profiles for select using (true);
create policy "update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Create the profile automatically from the sign-up form (display name + flag).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  dn text := left(trim(coalesce(new.raw_user_meta_data->>'display_name', '')), 24);
  cc text := upper(coalesce(new.raw_user_meta_data->>'country', ''));
begin
  if char_length(dn) < 2 then dn := 'player-' || left(new.id::text, 4); end if;
  if cc !~ '^[A-Z]{2}$' then cc := 'IN'; end if;
  insert into public.profiles (id, display_name, country) values (new.id, dn, cc)
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- scores ----------
create table if not exists public.scores (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
  score int not null check (score between 0 and 1000),
  duration_ms int not null check (duration_ms between 1000 and 3600000),
  runner text not null check (char_length(runner) between 1 and 24),
  created_at timestamptz not null default now(),
  -- light anti-cheat: reaching 1000 takes well over 20 seconds at any difficulty
  constraint plausible_pace check (score * 20 <= duration_ms)
);
create index if not exists scores_board_idx on public.scores (difficulty, score desc, duration_ms asc);
alter table public.scores enable row level security;
drop policy if exists "scores are public" on public.scores;
drop policy if exists "insert own scores" on public.scores;
create policy "scores are public" on public.scores for select using (true);
create policy "insert own scores" on public.scores for insert with check (auth.uid() = user_id);

-- one score per player every 10 seconds
create or replace function public.scores_rate_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.scores where user_id = new.user_id and created_at > now() - interval '10 seconds') then
    raise exception 'Too many scores, slow down';
  end if;
  return new;
end $$;
drop trigger if exists scores_rate_limit on public.scores;
create trigger scores_rate_limit before insert on public.scores
  for each row execute function public.scores_rate_limit();

-- best run per player per difficulty, with name and flag
create or replace view public.leaderboard with (security_invoker = true) as
select distinct on (s.user_id, s.difficulty)
  s.difficulty, s.score, s.duration_ms, s.runner, s.created_at, p.display_name, p.country
from public.scores s
join public.profiles p on p.id = s.user_id
order by s.user_id, s.difficulty, s.score desc, s.duration_ms asc;

-- ---------- feedback (also emailed via Web3Forms) ----------
create table if not exists public.feedback (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users on delete set null default auth.uid(),
  name text check (char_length(name) <= 60),
  email text check (char_length(email) <= 120),
  message text not null check (char_length(message) between 3 and 2000),
  created_at timestamptz not null default now()
);
alter table public.feedback enable row level security;
drop policy if exists "anyone can send feedback" on public.feedback;
create policy "anyone can send feedback" on public.feedback for insert
  with check (user_id is null or user_id = auth.uid());
-- no select policy: feedback is readable only from the Supabase dashboard

-- Delhi Dino: API permissions. Newer Supabase projects don't expose new tables to the
-- public API automatically, so grant exactly what the site needs. Row-level security
-- policies (in schema.sql) still decide which rows each player can touch.
grant usage on schema public to anon, authenticated;

-- everyone can read the board, names and flags
grant select on public.profiles, public.scores, public.leaderboard to anon, authenticated;

-- signed-in players can change their own flag/name and post their own scores
grant update (country, display_name) on public.profiles to authenticated;
grant insert (user_id, difficulty, score, duration_ms, runner) on public.scores to authenticated;

-- anyone can send feedback, nobody can read it through the API
grant insert (user_id, name, email, message) on public.feedback to anon, authenticated;
