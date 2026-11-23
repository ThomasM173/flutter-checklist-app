# Re-run of the self-contained-build brief: 23 Nov 2026

Branch: `flight-school-accountability`. Not merged. Re-run of the 15 Oct brief after Thomas unpaused the Supabase project. The code work (Phase 2) was already done on 15 Oct in `f26e692` (see `overnight_report_2026-10-16.md`), and no code has changed since, so this run only repeated the live checks.

No account or password was reset or changed. No secrets were printed to the repo or committed.

## Loud finding: sign-up is still broken live

`validate_invite_code` with a garbage code still returns `PGRST202: Could not find the function public.validate_invite_code(p_code)`. The 6 Oct migration `supabase/migrations/20261006100000_mandatory_invite_code.sql` has still not been applied to production. Until it is, nobody can create an account through the app. Applying it is a production schema write and needs Thomas's explicit go-ahead.

## Live checks

- **Supabase:** It's back after the unpause. Public DNS resolves it again, but the local Windows resolver was still caching the "does not exist" answer for a while. The database returned Cloudflare 521 for a few minutes, and auth returned 500 for a short time after that, before both came up.
- **get-weather:** Real METAR for EGTE (`EGTE 231920Z 13009KT 4000 -DZ BR SCT009 BKN025 10/09 Q1020`).
- **demo.pilot1 sign-in:** OK. The first attempt hit `Database error querying schema` while the project was still starting, and the retries succeeded.
- **apple.review1:** It already existed, so it was left alone. Sign-in is OK, and it is a `pilot` at Demo Flight School.
- **Demo Flight School invite code:** Unchanged from October (kept in the gitignored `DEV_CREDENTIALS.md`).
- **`pubspec.yaml`:** Still `1.0.1+100`.

## Needs Thomas's decision

1. Approve applying the 6 Oct invite-code migration to production. After that, re-run the garbage-code check.
