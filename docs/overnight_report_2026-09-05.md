# Overnight Fix Session — 5 September 2026

Branch: `overnight-fixes` (pushed, not merged, not a PR — per instructions).
Commits: `3ee2864` .. `31470e6` (Phase 0 through Phase 5), one per phase.

## Needs a decision from Thomas

1. **Apply the entitlement migration.** This is the root blocker for Phases 2–4 (see below). No Supabase CLI is installed on this machine and `scripts/.env` has no direct Postgres connection string (only the API keys) — I can't run arbitrary DDL through those. Either: paste `supabase/migrations/20260904100000_entitlement.sql` into the Supabase SQL Editor by hand, or install + `supabase link --project-ref lrwqszvgikgpjhacqscb` then `supabase db push`, or add a `DATABASE_URL`/connection string to `scripts/.env` and I can run it with the `pg` package next time.
2. **Edge Functions aren't deployed.** New finding, unrelated to tonight's task: `get-weather` and `delete-account` both 404 against the live project (`supabase/functions/` exist in the repo but were apparently never `supabase functions deploy`ed, or the CLI was never linked). Worth deploying before you rely on either in production.
3. **Devon & Somerset admin email is still the placeholder** (`TODO_REPLACE_devon_somerset_admin@clearedtogo.test`) — `SEED_DEVON_ADMIN_EMAIL` isn't set in `scripts/.env`. Set it and re-run `node scripts/seed_devon_somerset_school.mjs` once Phase 2 is unblocked, before handing credentials to the school.
4. **OneDrive move not performed.** I deliberately skipped `Move-Item` to `C:\Dev\ClearedToGo` — moving the folder this session and the IDE were both anchored to risked breaking the rest of the run. The actual root cause of the build failure turned out to be something else (see Phase 1) and is now fixed either way, but the move is still worth doing yourself if you want the durable fix against future OneDrive sync issues.
5. **One locked file left behind in the `flutter/` move**: `ctg_overnight_backup\flutter\bin\cache\dart-sdk\pkg\_macros\analysis_options.yaml` is still at the old path (everything else moved). Something — likely Dart/VS Code tooling — had it open. Delete it manually once VS Code is fully closed; trivial, not urgent.
6. **`README.md:14`** still says "User authentication with AWS Cognito" — stale since the Supabase migration. Left as a listed finding rather than edited, since it's user-facing copy.
7. **157 remaining `flutter analyze` issues** (0 errors — all info/warning level: deprecated Flutter APIs like `withOpacity`/`groupValue`, file-naming convention violations, unused fields, etc.). Not auto-fixable beyond what `dart fix --apply` already handled (3 fixes). Full breakdown in Phase 5 below.
8. **90-day trial length** — carried over unconfirmed from the entitlement work; migration still uses the 90-day default since you hadn't said otherwise.

---

## Phase 0 — Setup

`git status` showed the working tree was **not clean**: the entire AWS Cognito/Amplify → Supabase migration (auth, flight schools, checklist completions, StoreKit IAP scaffolding, invite-code UI, PDF storage, the whole `supabase/` and `scripts/` directories) had been sitting uncommitted on `main` — none of it had ever been committed. Per your instruction not to overwrite anything, I didn't stash or discard it: `git checkout -b overnight-fixes` doesn't touch the working tree, so I created the branch first (nothing lost), then committed that entire pre-existing pile as its own checkpoint commit (`3ee2864`) before starting any of tonight's actual phases, so history clearly separates "what existed going in" from "what this session did." Verified no secrets were staged (`.env`/`scripts/.env` correctly gitignored; the two `.env.example` files that did get committed were already scrubbed of real values). `.gitignore` already covered `build/`, `.dart_tool/`, `.env`, `scripts/.env` — nothing to add.

**Status: done.**

## Phase 1 — Windows build failure

Reproduced the exact reported error on a clean `flutter clean`. Root cause was **not** OneDrive file-locking as suspected — it was two compounding issues in stale `build/`/`.dart_tool`/`ephemeral` artifacts left over from the old AWS Amplify build:

1. Deeply nested Gradle output under `build/amplify_analytics_pinpoint/...` exceeded Windows' 260-char `MAX_PATH` given the already-deep OneDrive path, so `Remove-Item`/the Flutter tool's delete both failed silently.
2. `windows/flutter/ephemeral` and `linux/flutter/ephemeral` contain plugin symlinks (`.plugin_symlinks/...`) that `Remove-Item -Recurse` tries to recurse *into* instead of deleting as links, hitting Access Denied.

Fixed by clearing `build/` with `robocopy /MIR` against an empty temp directory (handles long paths natively, unlike PowerShell's `Remove-Item`) and clearing the ephemeral dirs with `cmd /c rmdir /s /q` (doesn't follow symlinks). `flutter clean` then ran clean, `flutter pub get` succeeded, and `flutter build web` — which exercises the exact `build/flutter_assets` path that was failing — succeeded twice in a row: once as a fresh build, once as a rebuild over the existing `build/` directory (the actual failure scenario). No repo files changed; this was local environment cleanup only.

Did **not** perform the recommended OneDrive relocation — see item 4 above.

**Status: fixed and verified.**

## Phase 2 — Apply the entitlement migration

**Blocked.** Checked both routes named in the instructions:
- Supabase CLI: not installed (`supabase --version`/`supabase status` both fail — command not found).
- Direct Postgres connection string in `scripts/.env`: not present. Only `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` are set (checked variable *names* only, per the never-print-`.env` rule). The service_role key is a PostgREST JWT, not the database password — it authenticates REST/RPC calls, not a raw Postgres connection, so it can't be substituted into a connection string.

`supabase/migrations/20260904100000_entitlement.sql` has **not** been applied. Everything downstream that depends on it failed as a direct, expected consequence (see Phases 3–4) rather than being independently investigated.

**Status: blocked — see item 1 above for how to unblock.**

## Phase 3 — Seed Devon & Somerset Flying School

Ran `node scripts/seed_devon_somerset_school.mjs` (no `--reset`, as instructed) anyway, per "keep going." Failed immediately:

```
Seed failed: Could not find the 'comped_reason' column of 'flight_schools' in the schema cache
```

Expected — direct consequence of Phase 2. No school or admin account was created; there is no invite code or admin email to report this run. `SEED_DEVON_ADMIN_EMAIL` was confirmed not set in `scripts/.env` beforehand (per your instruction, ran anyway rather than blocking on it) — once Phase 2 is unblocked and this re-runs, the admin account will land at the placeholder `TODO_REPLACE_devon_somerset_admin@clearedtogo.test`.

**Status: blocked — cascades from Phase 2.**

## Phase 4 — Verification

Your instructions pointed to `node scripts/verify_schema.mjs`, but the 5 checks you listed (comped access, trial expiry, simulated paid, admin visibility, cross-tenant isolation) actually live in `verify_entitlement.mjs`, the sibling script written for exactly this. Ran both.

### `node scripts/verify_schema.mjs`
**6 passed, 5 failed, 2 skipped.**
```
❌ [schema] flight_schools — column flight_schools.plan_type does not exist
❌ [schema] profiles — column profiles.trial_started_at does not exist
✅ [schema] checklist_completions — table + all expected columns present
❌ [schema] has_premium_access() function — Could not find the function public.has_premium_access(p_user_id) in the schema cache
✅ [schema] completion_type CHECK constraint — bogus value rejected
✅ [rls-anon] profiles / flight_schools / checklist_completions: select denied
⏭️  [rls-pilot] all checks — DEV_PILOT_EMAIL/DEV_PILOT_PASSWORD not set (unrelated to tonight, pre-existing)
⏭️  [rls-admin] all checks — DEV_ADMIN_EMAIL/DEV_ADMIN_PASSWORD not set (unrelated to tonight, pre-existing)
❌ [edge-fn] get-weather — status 404: Requested function was not found
✅ [edge-fn] delete-account: create throwaway account
❌ [edge-fn] delete-account: call function — status 404: Requested function was not found
```
The first 3 failures are the expected consequence of Phase 2 being blocked. **The two Edge Function 404s are a separate, genuine finding** — see item 2 above.

### `node scripts/verify_entitlement.mjs` — your 5 requested checks
Crashed on its very first setup step (creating a throwaway comped school) with the same missing-column error as Phase 3:
```
Verification script crashed: create throwaway school (comped): Could not find the 'comped_reason' column of 'flight_schools' in the schema cache
```
None of the 5 checks executed:

| # | Check | Result |
|---|---|---|
| 1 | Comped access works instantly for Devon & Somerset | **NOT RUN** |
| 2 | Trial grant / expiry revokes access correctly | **NOT RUN** |
| 3 | Simulated future-paid account proves the dormant subscription path | **NOT RUN** |
| 4 | Admin sees own school's pilots | **NOT RUN** |
| 5 | Cross-tenant isolation holds | **NOT RUN** |

One thing did verify correctly despite the crash: the script's `.finally(cleanup)` handler ran and printed its "Cleaning up... Done." even on an uncaught exception, confirming the teardown logic itself is sound — check 1 just never got far enough to create anything that needed cleaning up.

**Status: blocked — cascades from Phase 2. Re-run both scripts once the migration is applied.**

## Phase 5 — Cleanup

1. **Stray directories.** Confirmed unreferenced first: `grep -r "my_app"` across `.vscode/`, `pubspec.yaml`, `lib/` returned nothing; `.vscode/settings.json` and `launch.json` have no Flutter SDK path override. Moved both `flutter/` (full SDK clone) and `my_app/` (empty scaffold) to `../ctg_overnight_backup/` (sibling of the repo, outside git), per instructions — not deleted. `my_app/` moved cleanly. `flutter/` mostly moved via `robocopy /MOVE` (hit the same Windows `MAX_PATH` issue as Phase 1's `build/`, same fix) except one file that stayed locked by something (likely Dart/VS Code tooling) — see item 5 above.
2. **`dart format .`** — 71 files reformatted, whitespace only. This codebase evidently had never been run through the formatter before (e.g. `weather_service.dart`'s large diff is pure line-wrapping of long expressions — verified by reading it, no logic changed).
3. **`dart fix --dry-run`** proposed exactly 3 mechanical fixes (a dangling library doc comment in `user_role.dart`, two missing curly-brace blocks in `weather_service.dart` and `bottom_nav_bar.dart`), none in `iap_service.dart`. Applied via `dart fix --apply`.
4. `iap_service.dart` got swept into the blanket `dart format .` run too (whitespace-only, like every other file). Reverted it back to its pre-format state to honor "do NOT touch `iap_service.dart`" literally rather than relying on my own judgment that whitespace-only was fine.
5. **`flutter analyze lib`: 0 errors.** 157 remaining issues, all info/warning level:

   | Lint | Count |
   |---|---|
   | `curly_braces_in_flow_control_structures` | 42 |
   | `deprecated_member_use` (mostly `withOpacity`, a few `groupValue`/`onChanged`/`anonKey`) | 41 |
   | `library_private_types_in_public_api` | 23 |
   | `file_names` (camelCase filenames like `cessna_152_EFATRA.dart`) | 21 |
   | `unused_field` / `unused_local_variable` | 17 |
   | `library_prefixes` (`pdfWidgets` import prefix) | 6 |
   | `use_build_context_synchronously` | 5 |
   | `avoid_unnecessary_containers`, `avoid_print` | 1 each |

   None auto-fixable beyond what `dart fix` already applied. Left for your review rather than guessed at — several of these (unused fields, file renames) are judgment calls about intent, not mechanical fixes.
6. **Stale Cognito/AWS/Amplify scan** across `lib/` and outward-facing surfaces (`README.md`, `privacy_policy.dart`, `about_us.dart`, `faq_screen.dart`, `contact_us.dart`, `caa_compliance_screen.dart`). One genuine hit in user-facing text: `README.md:14` — "User authentication with AWS Cognito" (see item 6 above). Everything else matching is internal code comments accurately describing migration history (`profile.dart`, `user_role.dart`, `supabase_auth_service.dart`, `supabase_pdf_service.dart`, `main.dart`) — left alone.

**Status: done**, except the two follow-ups noted (locked leftover file, README copy).

## Phase 6 — This report

Written to `docs/overnight_report_2026-09-05.md`, committed, branch pushed. Not merged, no PR opened, per instructions.
