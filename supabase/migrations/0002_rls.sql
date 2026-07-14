-- Row Level Security: role-based access.
-- admin  -> sees/manages everything
-- others -> see only projects they are assigned to (via project_assignments)

-- Helper: is the current user an admin?
-- security definer so it can read profiles without triggering profiles' own RLS
-- (avoids infinite recursion in the profiles policies below).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Helper: is the current user assigned to a given project?
create or replace function public.is_assigned(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.project_assignments
    where project_id = p_project_id and user_id = auth.uid()
  );
$$;

-- Base table grants for the authenticated role. RLS policies below do the
-- actual gating; without these grants every query is denied outright.
grant select, insert, update, delete
  on public.profiles, public.projects, public.project_stages, public.project_assignments
  to authenticated;

alter table public.profiles            enable row level security;
alter table public.projects            enable row level security;
alter table public.project_stages      enable row level security;
alter table public.project_assignments enable row level security;

-- ---------- profiles ----------
create policy "profiles: read own or admin"
  on public.profiles for select
  using (id = auth.uid() or public.is_admin());

create policy "profiles: update own (non-role fields)"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles: admin manage"
  on public.profiles for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- projects ----------
create policy "projects: read assigned or admin"
  on public.projects for select
  using (public.is_admin() or public.is_assigned(id));

create policy "projects: admin write"
  on public.projects for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- project_stages ----------
create policy "stages: read if project visible"
  on public.project_stages for select
  using (public.is_admin() or public.is_assigned(project_id));

create policy "stages: admin write"
  on public.project_stages for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- project_assignments ----------
create policy "assignments: read own or admin"
  on public.project_assignments for select
  using (user_id = auth.uid() or public.is_admin());

create policy "assignments: admin write"
  on public.project_assignments for all
  using (public.is_admin())
  with check (public.is_admin());
