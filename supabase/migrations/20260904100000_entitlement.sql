-- ============================================================================
-- ClearedToGo — unified entitlement (trial + comped school + paid subscriber)
--
-- Launch model: every signed-up pilot gets a free trial; one or more flight
-- schools can be comped (unlimited free access for their pilots, no trial
-- clock); real StoreKit billing (subscription_status / subscription_expires_at,
-- already on profiles) is built but dormant behind the app's kIapEnabled flag
-- and can be switched on later with no schema change.
--
-- has_premium_access() is the SINGLE entitlement check for the whole app —
-- every call site that used to compare subscription_status = 'premium'
-- directly now resolves through this instead, so trial and comped users get
-- real access now, not just paying ones later.
-- ============================================================================

alter table public.profiles
  add column trial_started_at timestamptz not null default now(),
  add column trial_ends_at    timestamptz not null default (now() + interval '90 days');

comment on column public.profiles.trial_started_at is
  'When this pilot''s free trial began. Backfilled to now() for rows that existed before this migration.';
comment on column public.profiles.trial_ends_at is
  'Trial expiry. has_premium_access() grants access while this is in the future, independent of subscription_status or flight school.';

alter table public.flight_schools
  add column plan_type    text not null default 'standard' check (plan_type in ('standard', 'comped')),
  add column comped_reason text;

comment on column public.flight_schools.plan_type is
  '''standard'' (default) or ''comped''. Every pilot at a comped school gets has_premium_access() = true permanently, independent of their own trial/subscription.';
comment on column public.flight_schools.comped_reason is
  'Free-text note on why a school is comped (e.g. ''launch design partner''). Nullable; not shown to pilots.';

-- ---------------------------------------------------------------------------
-- has_premium_access(p_user_id)
--   true if ANY of:
--     a) the user's trial_ends_at is in the future
--     b) the user's flight school has plan_type = 'comped'
--     c) subscription_status = 'premium' and subscription_expires_at is in
--        the future (real paid subscriber — dormant until the app's
--        kIapEnabled flag flips on, but already resolves through this same
--        path once setSubscription() starts writing real purchases).
--   security definer so a pilot can always resolve their own access even
--   though flight_schools rows outside their own school are RLS-hidden.
--   p_user_id defaults to auth.uid() for client calls; the explicit override
--   is for the service-role seed/verify scripts.
-- ---------------------------------------------------------------------------
create or replace function public.has_premium_access(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    left join public.flight_schools fs on fs.id = p.flight_school_id
    where p.id = p_user_id
      and (
        p.trial_ends_at > now()
        or fs.plan_type = 'comped'
        or (p.subscription_status = 'premium' and p.subscription_expires_at > now())
      )
  );
$$;

comment on function public.has_premium_access(uuid) is
  'Single entitlement check for the whole app: active trial, comped flight school, or a live paid subscription. Do not check subscription_status directly anywhere else.';

revoke all on function public.has_premium_access(uuid) from public, anon;
grant execute on function public.has_premium_access(uuid) to authenticated;
