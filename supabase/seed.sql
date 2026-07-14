-- Seed data for LOCAL DEV ONLY. Runs on `supabase db reset`.
-- Two demo users (created directly in auth.users). Password for both: Password123!
--   admin@demo.com  -> role admin  (sees all projects)
--   worker@demo.com -> role worker (assigned to "Riverside Apartments" only)
-- pgcrypto's crypt/gen_salt live in the `extensions` schema on Supabase.

-- ---------- Demo auth users ----------
-- Token columns are set to '' (not NULL) — GoTrue fails to scan NULL token fields.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous,
  confirmation_token, recovery_token, email_change,
  email_change_token_new, email_change_token_current,
  phone_change, phone_change_token, reauthentication_token
) values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'admin@demo.com',
   extensions.crypt('Password123!', extensions.gen_salt('bf')),
   now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"full_name":"Admin User"}', false, false,
   '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'worker@demo.com',
   extensions.crypt('Password123!', extensions.gen_salt('bf')),
   now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"full_name":"Worker User"}', false, false,
   '', '', '', '', '', '', '', '');

-- Email/password identities (required for password login by GoTrue).
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
) values
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
   '{"sub":"11111111-1111-1111-1111-111111111111","email":"admin@demo.com","email_verified":true}',
   'email', now(), now(), now()),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
   '{"sub":"22222222-2222-2222-2222-222222222222","email":"worker@demo.com","email_verified":true}',
   'email', now(), now(), now());

-- The on_auth_user_created trigger already inserted profiles rows; promote the admin.
update public.profiles set role = 'admin'  where id = '11111111-1111-1111-1111-111111111111';
update public.profiles set role = 'worker' where id = '22222222-2222-2222-2222-222222222222';

-- ---------- Projects ----------
insert into public.projects (id, name, description, address, status, start_date, end_date) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Riverside Apartments',
   'A 6-storey residential building with 48 units along the river.',
   '120 Riverside Dr', 'active', '2026-01-15', '2027-06-30'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Downtown Office Tower',
   '18-floor commercial office tower with underground parking.',
   '500 Market St', 'planning', '2026-09-01', '2028-12-15'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Hillside Warehouse',
   'Industrial storage warehouse, 8,000 m2 footprint.',
   '77 Industrial Way', 'on_hold', '2025-11-01', '2026-08-01');

-- ---------- Stages ----------
insert into public.project_stages (project_id, name, sequence, status, start_date, end_date) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Site Preparation',      1, 'completed',   '2026-01-15', '2026-02-28'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Foundation',            2, 'completed',   '2026-03-01', '2026-05-15'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Structural Framing',    3, 'in_progress', '2026-05-16', '2026-10-30'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'MEP Rough-in',          4, 'not_started', null, null),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Interior Finishing',    5, 'not_started', null, null),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Design & Permitting',   1, 'in_progress', '2026-09-01', '2027-01-31'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Excavation',            2, 'not_started', null, null),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Core & Shell',          3, 'not_started', null, null),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Grading',               1, 'blocked',     '2025-11-01', null),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Slab & Foundation',     2, 'not_started', null, null);

-- ---------- Assignments ----------
-- Worker can see only the Riverside Apartments project.
insert into public.project_assignments (project_id, user_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222');
