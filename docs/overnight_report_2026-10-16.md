# Self-contained iOS build + live checks — 15/16 Oct 2026

Branch: `flight-school-accountability`. Not merged to `main`. Session spanned the date rollover from 15 to 16 Oct.

## Hard rules followed

No existing account or password was reset or changed. No service role key, database password, or Supabase access token was printed, committed, or bundled — only the public anon/publishable key, which was already visible in the local `.env` and is now also a compile-time fallback constant in `lib/config/env.dart`.

## Loud finding — sign-up is broken live

**`validate_invite_code()` does not exist on the production database.** Calling it (as `signup_screen.dart` does before every signup attempt) returns `PGRST202 — Could not find the function public.validate_invite_code(p_code) in the schema cache`. This function, along with the rest of `handle_new_user()`'s "invite code is now mandatory" behaviour, was added in `supabase/migrations/20261006100000_mandatory_invite_code.sql`, committed on 6 Oct — but that migration was apparently never actually pushed to the live project. This session's brief assumed it was already live; it isn't.

**Impact: nobody can currently create a new account through the app** — reviewer or real user, with or without a valid invite code — they'll hit this error on submit. This needs a `supabase db push` (a schema-altering write to production, so it needs Thomas's explicit go-ahead, same as it did on 2 Oct) before App Store review or any real signup can work. Existing accounts are unaffected — sign-in works fine, confirmed below.

## Phase 0 — Setup ✅

Clean, on `flight-school-accountability`, in sync with origin.

## Phase 1 — Confirm Supabase is back ✅

DNS now resolves (`lrwqszvgikgpjhacqscb.supabase.co` → `104.18.38.10` / `172.64.149.246`, confirmed via Google's public DNS). `get-weather` returned real METAR for EGTE (`EGTE 152150Z 17004KT 130V210 9999 BKN009 16/14 Q1018`). The 12 Oct outage has resolved itself — no idea what caused it, didn't investigate further since the task only asked to confirm it's back.

## Phase 2 — Zero-UI-setup Codemagic build ✅

- `lib/config/env.dart`: added fallback constants holding the same public `SUPABASE_URL` and anon key already in the local `.env`. Verified the key is the publishable one (`sb_publishable_` prefix, not a JWT, not service_role) before committing it.
- `lib/main.dart`: `dotenv.load()` wrapped in try/catch — a missing `.env` is now an expected case, not a startup crash.
- `pubspec.yaml`: removed `.env` from `assets`. It's gitignored, so a fresh checkout has none, and a *declared-but-missing* asset fails `flutter build` outright — the runtime try/catch can't fix that class of failure. The fallback constants make bundling it unnecessary. Side effect: a local `.env` is no longer read by the running app at all (it's not bundled, so `flutter_dotenv` can't load it via `rootBundle` even though the file still exists on disk) — kept around only for `.env.example`-style documentation now.
- Verified: `flutter analyze lib` holds at 153 (baseline, no new issues). Simulated a fresh checkout by moving `.env` aside — `flutter build web --release` succeeded (proves the asset fix), and `flutter run -d edge --release` reached the running-app prompt with no crash (proves the runtime fallback works) — then restored `.env`.
- `codemagic.yaml` from 12 Oct: **left in place, not deleted.** Not wrong, still useful for the signing/publishing steps, but its "write `.env` from Codemagic variables" step is now redundant — the app works with zero environment variables configured in Codemagic at all. **One-line verdict: safe to ignore/leave as-is, but its mere presence in the repo root may push Codemagic into "yaml mode" over the Workflow Editor for this app** — if you want to configure via the Workflow Editor UI instead, check Codemagic's app settings for which config source it's using.

## Phase 3 — Non-destructive live checks

1. `validate_invite_code` with a garbage code: **function doesn't exist** — see the loud finding above. Not the clean "invalid" result expected.
2. Signed in as `demo.pilot1@clearedtogo.test` with its existing password from `docs/DEV_CREDENTIALS.md` — **succeeded**, nothing was reset.
3. Created `apple.review1@clearedtogo.test` (didn't already exist) — pre-confirmed pilot, attached to Demo Flight School, role `pilot`. Verified it signs in correctly. Appended to `docs/DEV_CREDENTIALS.md` (gitignored).
4. Demo Flight School invite code read and appended to `docs/DEV_CREDENTIALS.md` (gitignored) — not reproduced here, see that file locally.

## Phase 4 — Apple notes file

`docs/APPLE_REVIEW_NOTES.md` (gitignored) updated with real values: the new reviewer account, `demo.pilot1` as backup, the real invite code, the guest path, and the account-deletion path. Opens with the same loud warning as above so Thomas doesn't paste it into App Store Connect believing sign-up works.

## Phase 5 — Finish

`pubspec.yaml` confirmed still `1.0.1+100`. Code changes committed and pushed (this report + the Phase 2 commit before it) — no credential or notes files committed, all three (`DEV_CREDENTIALS.md`, `APPLE_REVIEW_NOTES.md`, `APPLE_RESUBMIT_CHECKLIST.md`) stay gitignored.

**Needs Thomas's decision:**
1. Push `supabase/migrations/20261006100000_mandatory_invite_code.sql` live (needs explicit approval — it's a production schema write). Nothing works for new signups until this happens.
2. Re-verify Phase 3.1 (the garbage-code check) once that's pushed, to confirm it actually resolves.
3. Everything else from this session is otherwise ready.
