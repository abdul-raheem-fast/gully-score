-- Add soft-delete flag and audit logs for admin actions.

alter table public.profiles
  add column if not exists is_blocked boolean not null default false;

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_user_id uuid references auth.users(id) on delete set null,
  target_team_id uuid references public.teams(id) on delete set null,
  details jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_audit_logs_admin on public.admin_audit_logs(admin_user_id);
create index if not exists idx_admin_audit_logs_action on public.admin_audit_logs(action);
create index if not exists idx_admin_audit_logs_created_at on public.admin_audit_logs(created_at);

alter table public.admin_audit_logs enable row level security;

drop policy if exists "admin audit read" on public.admin_audit_logs;
create policy "admin audit read"
  on public.admin_audit_logs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );
