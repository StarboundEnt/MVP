-- Create application schema for remote API backing tables
create schema if not exists app_public;

-- Enum describing available complexity levels in the mobile app
create type app_public.complexity_level as enum ('stable', 'trying', 'overloaded', 'survival');

-- Helper function to keep updated_at timestamps current
create or replace function app_public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

-- Application users table (separate from Supabase auth identities)
create table if not exists app_public.users (
  id bigserial primary key,
  auth_user_id uuid references auth.users(id),
  username text not null unique,
  display_name text not null,
  complexity_profile app_public.complexity_level not null default 'stable',
  onboarding_complete boolean not null default false,
  notifications_enabled boolean not null default false,
  notification_time text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists users_auth_user_id_unique_idx
  on app_public.users (auth_user_id)
  where auth_user_id is not null;

create trigger set_users_updated_at
before update on app_public.users
for each row
execute function app_public.set_updated_at();

alter table app_public.users enable row level security;

create policy "service_role_full_access"
  on app_public.users
  as permissive
  for all
  to service_role
  using (true)
  with check (true);

create policy "users_select_own_profile"
  on app_public.users
  as permissive
  for select
  to authenticated
  using (auth.uid() is not null and auth.uid() = auth_user_id);

create policy "users_update_own_profile"
  on app_public.users
  as permissive
  for update
  to authenticated
  using (auth.uid() is not null and auth.uid() = auth_user_id)
  with check (auth.uid() is not null and auth.uid() = auth_user_id);
