-- ============================================================================
-- ClearedToGo — functions & triggers
--   * helper functions used by RLS (security definer to avoid the classic
--     "policy on profiles selects from profiles" infinite-recursion trap)
--   * handle_new_user() : auto-create a profiles row on signup
--   * join_flight_school() / rotate_flight_school_invite_code() : the
--     invite-code membership flow
-- ============================================================================

-- ---------------------------------------------------------------------------
-- RLS helper functions
--   SECURITY DEFINER + fixed search_path so they read profiles WITHOUT
--   triggering the caller's RLS policies.
-- ---------------------------------------------------------------------------
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

comment on function public.current_user_role() is
  'Role of the currently authenticated user, read bypassing RLS. Safe to call from RLS policies.';

create or replace function public.current_user_flight_school_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select flight_school_id from public.profiles where id = auth.uid();
$$;

comment on function public.current_user_flight_school_id() is
  'flight_school_id of the currently authenticated user, read bypassing RLS. Safe to call from RLS policies.';

-- ---------------------------------------------------------------------------
-- handle_new_user()
--   Fires after every auth.users insert (email/password signup, OAuth, or a
--   service-role admin.createUser call). Creates the matching profiles row.
--
--   role is ALWAYS 'pilot' here. Client signup metadata is untrusted, so an
--   admin role can only be granted afterwards by the service role (the seed
--   script does exactly this). full_name is taken from signup metadata if the
--   client supplied it.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    'pilot'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- join_flight_school(invite_code)
--   Lets an authenticated pilot attach their own profile to a school by
--   entering the school's invite code. Runs as definer so it can write
--   profiles.flight_school_id (that column is revoked from the client).
-- ---------------------------------------------------------------------------
create or replace function public.join_flight_school(p_invite_code text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_school_id uuid;
  v_profile   public.profiles;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if public.current_user_role() = 'flight_school_admin' then
    raise exception 'Flight school admins cannot join another school' using errcode = '42501';
  end if;

  select id into v_school_id
  from public.flight_schools
  where invite_code = upper(trim(p_invite_code));

  if v_school_id is null then
    raise exception 'Invalid invite code' using errcode = 'P0002';
  end if;

  update public.profiles
     set flight_school_id = v_school_id
   where id = auth.uid()
   returning * into v_profile;

  return v_profile;
end;
$$;

revoke all on function public.join_flight_school(text) from public, anon;
grant execute on function public.join_flight_school(text) to authenticated;

-- Allow a pilot to leave their school (clears the denormalised link on future
-- completions only; historical completions keep their snapshot).
create or replace function public.leave_flight_school()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if public.current_user_role() = 'flight_school_admin' then
    raise exception 'Flight school admins cannot leave their school' using errcode = '42501';
  end if;

  update public.profiles
     set flight_school_id = null
   where id = auth.uid()
   returning * into v_profile;

  return v_profile;
end;
$$;

revoke all on function public.leave_flight_school() from public, anon;
grant execute on function public.leave_flight_school() to authenticated;

-- ---------------------------------------------------------------------------
-- rotate_flight_school_invite_code()
--   Admin-only. Issues a fresh 8-char code for the caller's school.
-- ---------------------------------------------------------------------------
create or replace function public.rotate_flight_school_invite_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_school_id uuid;
  v_code      text;
begin
  select flight_school_id into v_school_id
  from public.profiles where id = auth.uid();

  if v_school_id is null or public.current_user_role() <> 'flight_school_admin' then
    raise exception 'Only a flight school admin can rotate the invite code' using errcode = '42501';
  end if;

  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    begin
      update public.flight_schools set invite_code = v_code where id = v_school_id;
      exit;
    exception when unique_violation then
      -- astronomically unlikely; retry
    end;
  end loop;

  return v_code;
end;
$$;

revoke all on function public.rotate_flight_school_invite_code() from public, anon;
grant execute on function public.rotate_flight_school_invite_code() to authenticated;
