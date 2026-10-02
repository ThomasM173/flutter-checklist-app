-- ============================================================================
-- ClearedToGo — make the flight-school invite code compulsory at signup
--
-- Reverses the "empty/invalid code falls back to Independent Pilots" behaviour
-- from 20261001110000_signup_invite_code.sql, deliberately: a missing or
-- invalid invite code now blocks account creation instead of silently
-- attaching the new pilot to a catch-all nobody chose. Independent Pilots
-- keeps existing as a real school (created in 20261001100000 with its own
-- random invite_code already) — genuinely unaffiliated pilots still have a
-- path in, just by entering that school's own code like any other, not an
-- invisible default.
--
-- Also adds validate_invite_code(), a SECURITY DEFINER function grantable to
-- anon: the signup form needs to check a code BEFORE calling auth.signUp(),
-- but flight_schools has no anon SELECT grant (RLS scopes authenticated
-- reads to the caller's own school only) — this is the one narrow exception,
-- returning only a boolean, never school details.
-- ============================================================================

create or replace function public.validate_invite_code(p_code text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.flight_schools
    where invite_code = upper(trim(p_code))
  );
$$;

revoke all on function public.validate_invite_code(text) from public;
grant execute on function public.validate_invite_code(text) to anon, authenticated;

comment on function public.validate_invite_code(text) is
  'Anon-callable pre-check for the signup form: does this invite code match a real flight school? Returns a bare boolean only - never exposes which school or any other flight_schools column.';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite_code text;
  v_school_id   uuid;
begin
  v_invite_code := nullif(trim(new.raw_user_meta_data ->> 'invite_code'), '');

  if v_invite_code is null then
    raise exception 'Invite code required' using errcode = 'P0002';
  end if;

  select id into v_school_id
  from public.flight_schools
  where invite_code = upper(v_invite_code);

  if v_school_id is null then
    raise exception 'Invalid invite code' using errcode = 'P0002';
  end if;

  insert into public.profiles (id, full_name, role, flight_school_id)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    'pilot',
    v_school_id
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

comment on function public.handle_new_user() is
  'Fires after every auth.users insert. Creates the matching profiles row, always role=pilot, attached to the school named by signup metadata invite_code. Raises P0002 if the code is missing or does not match a real school - there is no Independent Pilots fallback anymore, that school is only reached by entering its own invite code like any other.';
