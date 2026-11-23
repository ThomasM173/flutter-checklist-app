# Re-run of the self-contained-build brief: 23 Nov 2026

Branch: `flight-school-accountability`. Not merged. Re-run of the 15 Oct brief after Thomas unpaused the Supabase project. The code work (Phase 2) was already done on 15 Oct in `f26e692` (see `overnight_report_2026-10-16.md`), and no code has changed since, so this run only repeated the live checks. It then verified the invite-code migration once Thomas applied it.

No existing account or password was reset or changed. No secrets were printed to the repo or committed.

## Invite-code migration: now live and verified

The 6 Oct migration `supabase/migrations/20261006100000_mandatory_invite_code.sql` was applied to production by Thomas through the dashboard SQL Editor. The Supabase CLI was not used. Before he ran it, the file was read and confirmed to only create `validate_invite_code(text)` and replace `handle_new_user()`, with no row changes.

An earlier CLI attempt failed because the access token in `scripts/.env` is rejected as invalid (HTTP 401 from the management API). That token should be regenerated or removed. Because the migrations were applied through the SQL Editor, the remote migration history is probably empty. Don't run `supabase db push` against this project without repairing that history first, or it will try to re-apply everything.

Live checks after the migration:

| Check | Result |
|---|---|
| `validate_invite_code('GARBAGE1')` as anon (publishable key, no session) | `false`, HTTP 200. No permission error, so no extra GRANT is needed |
| `validate_invite_code(<Demo Flight School code>)` as anon | `true`, HTTP 200 |
| Public sign-up with no invite code | Rejected: `Database error saving new user` (the trigger raised), and no auth user was left behind |
| Public sign-up with a garbage invite code | Rejected in the same way, and no auth user was left behind |
| New user with the Independent Pilots invite code | Created. The profile is `role=pilot` in Independent Pilots |
| `apple.review1` and `demo.pilot1` sign in | Both OK |
| Test account cleanup | Deleted through the `delete-account` Edge Function (the app's Account → Delete Account path). The auth user returns 404 and the profile row is gone. No `invite.*` test accounts remain |

The accepted-path test did not go through the public `/auth/v1/signup` endpoint. That endpoint refused before reaching the database, first with `email_address_invalid` because `.test` addresses are undeliverable, then with `over_email_send_rate_limit`. So the user was created through the admin API with the same `invite_code` metadata. That fires the same `handle_new_user` trigger and skips only the confirmation email.

## Risk to check before review: confirmation emails

That rate limit suggests the project is still on Supabase's built-in email sender. The built-in sender has a very low hourly limit and may only deliver to the project team's own addresses. If so, an App Review tester who tries to create a new account with their own email could get an error or never receive the confirmation email. The review itself doesn't depend on this, because the reviewer is given a ready-made account and the guest path. It is worth confirming in Dashboard → Authentication → Emails (custom SMTP), or testing a sign-up with a real non-team address, before release.

## Other live checks (before the migration)

- **Supabase:** Back after the unpause. The local Windows DNS cache held the old "does not exist" answer for a while. The database returned Cloudflare 521 and auth returned 500 for a few minutes before both came up.
- **get-weather:** Real METAR for EGTE (`EGTE 231920Z 13009KT 4000 -DZ BR SCT009 BKN025 10/09 Q1020`).
- **apple.review1:** Already existed, so it was left alone.
- **`pubspec.yaml`:** Still `1.0.1+100`.
