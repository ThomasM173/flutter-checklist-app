-- ============================================================================
-- ClearedToGo — grant has_premium_access() to service_role
--
-- 20260904100000_entitlement.sql's `revoke all ... from public, anon` also
-- stripped the implicit PUBLIC-role EXECUTE grant Postgres gives every new
-- function by default — which service_role was silently relying on (same
-- gap exists for every other RPC in this codebase; it never mattered before
-- because real calls always go through the authenticated role via a signed-in
-- user's JWT, never service_role). It only surfaces when admin/service-role
-- tooling (seed/verify scripts) calls has_premium_access() directly, which
-- 20260909's overnight session did while confirming the migration was live.
--
-- Safe: service_role already has full database access via BYPASSRLS: this
-- just lets it call a read-only boolean entitlement check directly instead
-- of needing to sign in as the user being checked.
-- ============================================================================

grant execute on function public.has_premium_access(uuid) to service_role;
