-- ============================================================================
-- ClearedToGo — Row Level Security
--
-- Strategy: revoke Supabase's default broad grants on every app table, then
-- grant back only the exact privileges each role needs, and gate rows with
-- policies. Column-level grants on profiles are what actually stop a client
-- escalating its own role / school; the SECURITY DEFINER functions in
-- 20260903120100 are the sanctioned way those columns change.
-- ============================================================================

alter table public.flight_schools        enable row level security;
alter table public.profiles              enable row level security;
alter table public.checklist_completions enable row level security;

-- ===========================================================================
-- profiles
-- ===========================================================================
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, license_number, home_base,
              subscription_status, subscription_product_id, subscription_expires_at)
  on public.profiles to authenticated;
-- NOTE: no grant on (role, flight_school_id) -> client cannot change them.
-- NOTE: no insert/delete -> handled by trigger + auth.users cascade.

create policy "profiles: self read"
  on public.profiles for select
  to authenticated
  using ( id = auth.uid() );

create policy "profiles: admin reads own-school pilots"
  on public.profiles for select
  to authenticated
  using (
    public.current_user_role() = 'flight_school_admin'
    and role = 'pilot'
    and flight_school_id is not null
    and flight_school_id = public.current_user_flight_school_id()
  );

create policy "profiles: self update"
  on public.profiles for update
  to authenticated
  using ( id = auth.uid() )
  with check ( id = auth.uid() );

-- ===========================================================================
-- flight_schools
-- ===========================================================================
revoke all on public.flight_schools from anon, authenticated;
grant select on public.flight_schools to authenticated;
grant update (name, address, phone, email) on public.flight_schools to authenticated;
-- invite_code is intentionally NOT granted: changes only via
-- public.rotate_flight_school_invite_code(). Rows are created by the seed
-- script (service role) only.

create policy "flight_schools: members read own school"
  on public.flight_schools for select
  to authenticated
  using ( id = public.current_user_flight_school_id() );

create policy "flight_schools: admin updates own school"
  on public.flight_schools for update
  to authenticated
  using (
    id = public.current_user_flight_school_id()
    and public.current_user_role() = 'flight_school_admin'
  )
  with check (
    id = public.current_user_flight_school_id()
    and public.current_user_role() = 'flight_school_admin'
  );

-- ===========================================================================
-- checklist_completions
-- ===========================================================================
revoke all on public.checklist_completions from anon, authenticated;
grant select, insert on public.checklist_completions to authenticated;
-- no update/delete from the client for now (append-only audit record).
-- Account deletion purges these via the auth.users -> profiles -> completions
-- cascade, plus the delete-account Edge Function clears storage objects.

create policy "completions: pilot inserts own"
  on public.checklist_completions for insert
  to authenticated
  with check ( user_id = auth.uid() );

create policy "completions: pilot reads own"
  on public.checklist_completions for select
  to authenticated
  using ( user_id = auth.uid() );

create policy "completions: admin reads own-school rows"
  on public.checklist_completions for select
  to authenticated
  using (
    public.current_user_role() = 'flight_school_admin'
    and flight_school_id is not null
    and flight_school_id = public.current_user_flight_school_id()
  );
