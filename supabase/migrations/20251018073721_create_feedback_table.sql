-- Feedback storage table for in-app submissions
create type app_public.feedback_status as enum ('received', 'in_review', 'resolved');

create table if not exists app_public.feedback (
  id bigserial primary key,
  user_id bigint references app_public.users(id) on delete set null,
  category text not null,
  message text not null,
  metadata jsonb not null default '{}'::jsonb,
  status app_public.feedback_status not null default 'received',
  submitted_at timestamptz not null default timezone('utc', now()),
  processed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists feedback_user_id_idx on app_public.feedback (user_id);
create index if not exists feedback_status_idx on app_public.feedback (status);

create trigger set_feedback_updated_at
before update on app_public.feedback
for each row
execute function app_public.set_updated_at();

alter table app_public.feedback enable row level security;

create policy "service_role_feedback_full_access"
  on app_public.feedback
  as permissive
  for all
  to service_role
  using (true)
  with check (true);

create policy "users_view_own_feedback"
  on app_public.feedback
  as permissive
  for select
  to authenticated
  using (
    user_id is null
    or exists (
      select 1
      from app_public.users u
      where u.id = feedback.user_id
        and u.auth_user_id = auth.uid()
    )
  );

create policy "users_submit_feedback"
  on app_public.feedback
  as permissive
  for insert
  to authenticated
  with check (
    user_id is null
    or exists (
      select 1
      from app_public.users u
      where u.id = feedback.user_id
        and u.auth_user_id = auth.uid()
    )
  );
