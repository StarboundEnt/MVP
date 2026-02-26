-- Seed data for local development of Starbound backend
insert into app_public.users (username, display_name, complexity_profile, onboarding_complete)
values
  ('demo-user', 'Demo User', 'stable', true)
on conflict (username) do update set
  display_name = excluded.display_name,
  complexity_profile = excluded.complexity_profile,
  onboarding_complete = excluded.onboarding_complete;
