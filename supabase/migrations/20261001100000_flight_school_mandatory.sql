-- ============================================================================
-- ClearedToGo — mandatory flight-school membership + business_admin role
--
-- Every pilot now belongs to exactly one flight school: a real one (joined
-- via invite code) or the catch-all "Independent Pilots" school created here
-- for anyone who never entered one. This lets every completion, dashboard
-- query and RLS policy assume flight_school_id is always present instead of
-- branching on null.
--
-- Also adds a business_admin role: the ClearedToGo team's own account,
-- deliberately able to read/write across every school (unlike
-- flight_school_admin, which stays scoped to its own school — that
-- cross-tenant isolation is NOT weakened by anything in this migration).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Default catch-all school
-- ---------------------------------------------------------------------------
insert into public.flight_schools (name, invite_code, plan_type)
select
  'Independent Pilots',
  upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  'standard'
where not exists (
  select 1 from public.flight_schools where name = 'Independent Pilots'
);

comment on table public.flight_schools is
  'A flight school / training organisation, OR the "Independent Pilots" catch-all for pilots not affiliated with a real school. Admins belong to exactly one; pilots join one via invite_code or are auto-attached to the catch-all on signup.';

-- ---------------------------------------------------------------------------
-- 2. Backfill existing null flight_school_id -> the catch-all
--
--    Only touches rows that are ALREADY null. Anyone already attached to a
--    real school (Devon & Somerset's admin/pilots, the dev admin attached to
--    "Dev Flight School") is untouched by definition — this WHERE clause
--    can't reassign them. The dev pilot account (dev.pilot@clearedtogo.test)
--    IS currently null and WILL be attached to Independent Pilots here —
--    that's the intended effect of making membership mandatory, not a bug:
--    it was deliberately unaffiliated to test the "no school" trial path,
--    which mandatory membership retires. verify_entitlement.mjs's own
--    throwaway accounts are unaffected (created/deleted per run, not present
--    at migration time).
-- ---------------------------------------------------------------------------
update public.profiles
   set flight_school_id = (select id from public.flight_schools where name = 'Independent Pilots')
 where flight_school_id is null;

-- ---------------------------------------------------------------------------
-- 3. Make membership mandatory going forward
-- ---------------------------------------------------------------------------
alter table public.profiles
  alter column flight_school_id set not null;

-- handle_new_user() must attach every new signup somewhere immediately, or
-- this NOT NULL constraint breaks signup outright. The default school is
-- looked up by name rather than hardcoding its id (which is
-- environment-specific / only known after the insert above runs).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_default_school_id uuid;
begin
  select id into v_default_school_id
  from public.flight_schools
  where name = 'Independent Pilots';

  insert into public.profiles (id, full_name, role, flight_school_id)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    'pilot',
    v_default_school_id
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. business_admin role
--
--    role is a plain text + CHECK column, not a native enum (confirmed
--    against 20260903120000_init_schema.sql before writing this — do not
--    assume ALTER TYPE ... ADD VALUE syntax applies). The CHECK constraint
--    was declared inline with no explicit name, so it carries Postgres's
--    auto-generated name (profiles_role_check for a column-level check on
--    profiles.role) — found and dropped dynamically below instead of
--    hardcoding that name, in case it's ever different.
-- ---------------------------------------------------------------------------
do $$
declare
  v_conname text;
begin
  select conname into v_conname
  from pg_constraint
  where conrelid = 'public.profiles'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%role%pilot%flight_school_admin%';

  if v_conname is not null then
    execute format('alter table public.profiles drop constraint %I', v_conname);
  end if;
end $$;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('pilot', 'flight_school_admin', 'business_admin'));

comment on column public.profiles.role is
  'pilot | flight_school_admin | business_admin. Only changeable by the service role (seed script) — locked from client writes.';

-- ---------------------------------------------------------------------------
-- 5. business_admin: cross-tenant READ (RLS) — adds to, never replaces, the
--    existing self/own-school policies. Pilots and flight_school_admins keep
--    exactly the isolation they had before this migration.
-- ---------------------------------------------------------------------------
create policy "profiles: business_admin reads all"
  on public.profiles for select
  to authenticated
  using ( public.current_user_role() = 'business_admin' );

create policy "flight_schools: business_admin reads all"
  on public.flight_schools for select
  to authenticated
  using ( public.current_user_role() = 'business_admin' );

create policy "completions: business_admin reads all"
  on public.checklist_completions for select
  to authenticated
  using ( public.current_user_role() = 'business_admin' );
  -- Needed by the Phase 10 business dashboard (platform-wide completion
  -- counts) — added here rather than as a separate later migration since
  -- it's the same business_admin check as the two policies above.

-- ---------------------------------------------------------------------------
-- 6. business_admin: cross-tenant WRITE — via SECURITY DEFINER functions,
--    not a column grant. profiles.role / profiles.flight_school_id and
--    flight_schools.invite_code are deliberately NOT granted to
--    `authenticated` at all (see 20260903120200_rls_policies.sql) — the
--    existing convention in this codebase is that sensitive column changes
--    go through an explicit, auditable RPC rather than broadening a grant
--    and relying on RLS alone to gate it. Kept that pattern rather than
--    introducing a different one for business_admin.
-- ---------------------------------------------------------------------------
create or replace function public.business_admin_update_profile(
  p_profile_id uuid,
  p_role text default null,
  p_flight_school_id uuid default null
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles;
begin
  if public.current_user_role() <> 'business_admin' then
    raise exception 'Only a business admin can call this' using errcode = '42501';
  end if;

  update public.profiles
     set role = coalesce(p_role, role),
         flight_school_id = coalesce(p_flight_school_id, flight_school_id)
   where id = p_profile_id
   returning * into v_profile;

  if v_profile.id is null then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  return v_profile;
end;
$$;

revoke all on function public.business_admin_update_profile(uuid, text, uuid) from public, anon;
grant execute on function public.business_admin_update_profile(uuid, text, uuid) to authenticated;

create or replace function public.business_admin_update_school(
  p_school_id uuid,
  p_name text default null,
  p_plan_type text default null,
  p_comped_reason text default null,
  p_address text default null,
  p_phone text default null,
  p_email text default null
)
returns public.flight_schools
language plpgsql
security definer
set search_path = public
as $$
declare
  v_school public.flight_schools;
begin
  if public.current_user_role() <> 'business_admin' then
    raise exception 'Only a business admin can call this' using errcode = '42501';
  end if;

  update public.flight_schools
     set name          = coalesce(p_name, name),
         plan_type     = coalesce(p_plan_type, plan_type),
         comped_reason = coalesce(p_comped_reason, comped_reason),
         address       = coalesce(p_address, address),
         phone         = coalesce(p_phone, phone),
         email         = coalesce(p_email, email)
   where id = p_school_id
   returning * into v_school;

  if v_school.id is null then
    raise exception 'Flight school not found' using errcode = 'P0002';
  end if;

  return v_school;
end;
$$;

revoke all on function public.business_admin_update_school(uuid, text, text, text, text, text, text) from public, anon;
grant execute on function public.business_admin_update_school(uuid, text, text, text, text, text, text) to authenticated;
