-- Pre-configured demo data, applied to BOTH local (`db reset`) and Cloud (`db push`).
-- Two demo users created directly in auth.users. Password for both: Password123!
--   admin@demo.com  -> role admin  (sees all projects)
--   worker@demo.com -> role worker (assigned to "Riverside Apartments" only)
--
-- SECURITY NOTE: these are real, login-able accounts with a weak, publicly-known
-- password. Fine for a demo/interview project; for anything real, change or remove
-- them (and rotate the password) before exposing the deployment.
--
-- Everything here is idempotent (fixed UUIDs + `on conflict do nothing` / `update`),
-- so re-application is a no-op. pgcrypto's crypt/gen_salt live in `extensions` on Supabase.

-- ---------- Demo auth users ----------
-- Token columns are set to '' (not NULL) — GoTrue fails to scan NULL token fields.
-- Inserting into auth.users fires the on_auth_user_created trigger (from 0001),
-- which creates the matching public.profiles row from raw_user_meta_data.full_name.
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
   '', '', '', '', '', '', '', '')
on conflict (id) do nothing;

-- Email/password identities (required for password login by GoTrue).
-- Fixed ids so re-runs are idempotent (unique on (provider, provider_id)).
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
) values
  ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
   '{"sub":"11111111-1111-1111-1111-111111111111","email":"admin@demo.com","email_verified":true}',
   'email', now(), now(), now()),
  ('22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
   '{"sub":"22222222-2222-2222-2222-222222222222","email":"worker@demo.com","email_verified":true}',
   'email', now(), now(), now())
on conflict do nothing;

-- The on_auth_user_created trigger already inserted profiles rows; set their roles.
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
   '77 Industrial Way', 'on_hold', '2025-11-01', '2026-08-01')
on conflict (id) do nothing;

-- ---------- Stages ----------
-- Fixed ids so re-application is idempotent.
insert into public.project_stages (id, project_id, name, sequence, status, start_date, end_date) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Site Preparation',      1, 'completed',   '2026-01-15', '2026-02-28'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'Foundation',            2, 'completed',   '2026-03-01', '2026-05-15'),
  ('bbbbbbbb-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000001', 'Structural Framing',    3, 'in_progress', '2026-05-16', '2026-10-30'),
  ('bbbbbbbb-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0000-000000000001', 'MEP Rough-in',          4, 'not_started', null, null),
  ('bbbbbbbb-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000001', 'Interior Finishing',    5, 'not_started', null, null),
  ('bbbbbbbb-0000-0000-0000-000000000006', 'aaaaaaaa-0000-0000-0000-000000000002', 'Design & Permitting',   1, 'in_progress', '2026-09-01', '2027-01-31'),
  ('bbbbbbbb-0000-0000-0000-000000000007', 'aaaaaaaa-0000-0000-0000-000000000002', 'Excavation',            2, 'not_started', null, null),
  ('bbbbbbbb-0000-0000-0000-000000000008', 'aaaaaaaa-0000-0000-0000-000000000002', 'Core & Shell',          3, 'not_started', null, null),
  ('bbbbbbbb-0000-0000-0000-000000000009', 'aaaaaaaa-0000-0000-0000-000000000003', 'Grading',               1, 'blocked',     '2025-11-01', null),
  ('bbbbbbbb-0000-0000-0000-000000000010', 'aaaaaaaa-0000-0000-0000-000000000003', 'Slab & Foundation',     2, 'not_started', null, null)
on conflict (id) do nothing;

-- ---------- Assignments ----------
-- Worker is assigned ONLY to Riverside Apartments. Admin is assigned to
-- Downtown Office Tower so that at least one *other* project also has an
-- assignment row — this is what makes a broken is_assigned() (missing the
-- `user_id = auth.uid()` filter) observable: with the bug, the worker would
-- wrongly see Downtown too; with correct RLS the worker sees Riverside only.
insert into public.project_assignments (project_id, user_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111')
on conflict (project_id, user_id) do nothing;
