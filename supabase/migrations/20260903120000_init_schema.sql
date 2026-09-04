-- ============================================================================
-- ClearedToGo — initial Supabase schema
-- Replaces: AWS Cognito auth + on-device SharedPreferences "backend".
-- No data migration: clean cutover, no production users.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- flight_schools
--   Multi-tenant: each training organisation is one row.
--   invite_code lets a pilot self-join a school from the app (see
--   public.join_flight_school). Admins are attached by the seed script /
--   service role, never by the client.
-- ---------------------------------------------------------------------------
create table public.flight_schools (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  address     text,
  phone       text,
  email       text,
  invite_code text not null unique,
  created_at  timestamptz not null default now()
);

comment on table public.flight_schools is
  'A flight school / training organisation. Admins belong to exactly one; pilots optionally join one via invite_code.';

-- ---------------------------------------------------------------------------
-- profiles  (1:1 with auth.users)
--   Auto-created by public.handle_new_user() on signup.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id                      uuid primary key references auth.users(id) on delete cascade,
  full_name               text,
  role                    text not null default 'pilot'
                            check (role in ('pilot', 'flight_school_admin')),
  flight_school_id        uuid references public.flight_schools(id) on delete set null,
  license_number          text,
  home_base               text,
  subscription_status     text not null default 'free'
                            check (subscription_status in ('free', 'premium')),
  subscription_product_id text,
  subscription_expires_at timestamptz,
  created_at              timestamptz not null default now()
);

comment on table public.profiles is
  'Application profile for every auth user. Row auto-created by the on_auth_user_created trigger.';
comment on column public.profiles.role is
  'pilot | flight_school_admin. Only changeable by the service role (seed script) — locked from client writes.';
comment on column public.profiles.flight_school_id is
  'Admins: the school they administer (set by seed). Pilots: the school they joined — set ONLY through public.join_flight_school(). Locked from direct client writes.';
comment on column public.profiles.subscription_status is
  'free | premium. Client-writable for the Phase 4 StoreKit flow (RLS restricts to own row). Server-side renewal/expiry/refund tracking via App Store Server Notifications is a documented follow-up, not built.';
comment on column public.profiles.license_number is 'Pilot licence number — carried over from the old on-device account profile.';
comment on column public.profiles.home_base is 'Home base airfield — carried over from the old on-device account profile.';

create index profiles_flight_school_id_idx on public.profiles (flight_school_id);

-- ---------------------------------------------------------------------------
-- checklist_completions
--   One row per completed pre-boarding checklist. Retrievable by the pilot
--   who created it and by their flight school admin.
--   flight_school_id is DENORMALISED from the pilot's profile at completion
--   time so an admin keeps visibility of historical completions even if the
--   pilot later leaves (or switches) schools.
-- ---------------------------------------------------------------------------
create table public.checklist_completions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  flight_school_id uuid references public.flight_schools(id) on delete set null,
  aircraft_type    text not null,
  checklist_name   text not null,
  completed_at     timestamptz not null default now(),
  pdf_storage_path text,
  created_at       timestamptz not null default now()
);

comment on table public.checklist_completions is
  'One row per completed pre-boarding checklist. flight_school_id is denormalised at completion time (see column comment).';
comment on column public.checklist_completions.flight_school_id is
  'Snapshot of the pilot''s flight_school_id at completion time. Not a live FK to the pilot''s current school.';
comment on column public.checklist_completions.pdf_storage_path is
  'Object path inside the private ''checklist-pdfs'' storage bucket, e.g. {user_id}/{completion_id}.pdf';

create index checklist_completions_user_id_idx on public.checklist_completions (user_id);
create index checklist_completions_flight_school_id_idx on public.checklist_completions (flight_school_id);
create index checklist_completions_completed_at_idx on public.checklist_completions (completed_at desc);
