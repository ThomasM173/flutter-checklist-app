-- ============================================================================
-- ClearedToGo — invite code at signup
--
-- handle_new_user() now reads an optional `invite_code` from signup
-- metadata: a valid code attaches the new profile straight to that school; a
-- missing or invalid code falls back to "Independent Pilots" (same as
-- before this migration, when every new signup went there unconditionally).
-- Never raises — a bad invite code must not block account creation.
--
-- This runs server-side inside the trigger specifically because it can't
-- wait for a client-side RPC call after signUp(): with email confirmations
-- enabled (confirmed live via /auth/v1/settings — mailer_autoconfirm is
-- false on this project, despite local config.toml saying otherwise),
-- signUp() returns no session until the user confirms, and
-- join_flight_school() needs auth.uid() from an active session. Resolving
-- the school inside the trigger sidesteps that entirely.
-- ============================================================================

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

  if v_invite_code is not null then
    select id into v_school_id
    from public.flight_schools
    where invite_code = upper(v_invite_code);
  end if;

  if v_school_id is null then
    select id into v_school_id
    from public.flight_schools
    where name = 'Independent Pilots';
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
  'Fires after every auth.users insert. Creates the matching profiles row, always role=pilot, attached to the school named by signup metadata invite_code if valid, otherwise the Independent Pilots catch-all. Never raises on a bad invite code.';
