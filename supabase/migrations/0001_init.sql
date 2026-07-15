-- Construction company: core schema
-- Enums, tables, and the auth -> profiles trigger.

-- ---------- Enums ----------
create type public.user_role as enum ('admin', 'manager', 'worker');
create type public.project_status as enum ('planning', 'active', 'on_hold', 'completed');
create type public.stage_status as enum ('not_started', 'in_progress', 'completed', 'blocked');

-- ---------- Tables ----------
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  full_name  text,
  role       public.user_role not null default 'admin',
  created_at timestamptz not null default now()
);
comment on table public.profiles is 'Application user profile, one row per auth.users id.';

create table public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  address     text,
  status      public.project_status not null default 'planning',
  start_date  date,
  end_date    date,
  created_at  timestamptz not null default now()
);

create table public.project_stages (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  name       text not null,
  sequence   int not null,
  status     public.stage_status not null default 'not_started',
  start_date date,
  end_date   date,
  created_at timestamptz not null default now()
);
create index project_stages_project_id_idx on public.project_stages (project_id);

create table public.project_assignments (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (project_id, user_id)
);
create index project_assignments_user_id_idx on public.project_assignments (user_id);

-- ---------- Auth trigger: auto-create a profile row ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
