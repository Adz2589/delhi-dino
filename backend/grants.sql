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
