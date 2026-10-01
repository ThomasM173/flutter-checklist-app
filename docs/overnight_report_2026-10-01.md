# Overnight Fix Session — Flight-School Accountability Layer (1 October 2026)

Branch: `flight-school-accountability`, branched off `overnight-fixes` (not merged into `main` - `overnight-fixes` was confirmed not yet merged in Phase 0). Pushed throughout, no PR opened.
18 commits, one (or a clearly-labeled part) per phase: `7532215`..`de2deae`.

## Needs a decision from Thomas

1. **`main` branch still diverged and unresolved.** Carried over from the 10 September session's finding (commit `e3c3e0a` on `overnight-fixes`): `origin/main` has one commit ("AND16 UPDATED") with real, non-superseded work mixed into files that are otherwise obsolete (the old PDF system). Not re-investigated this session - still sitting exactly as that report described it. This needs your actual judgment before anything on this branch merges anywhere near `main`.
2. **Weather still doesn't return real data.** `get-weather` is deployed and routes correctly (confirmed again this session - see Phase 1 of this report), but `AVWX_TOKEN` is still not set as a Supabase secret (checked `supabase secrets list` directly - only the platform's own auto-injected secrets exist). This is a paid third-party API key I have no access to; genuinely needs you to run `supabase secrets set AVWX_TOKEN=xxxxx`.
3. **"Independent Pilots" as the default school's name** - used exactly as instructed, but it's a product-naming decision, not a technical one. Easy to rename later (one row in `flight_schools`) if you want something else.
4. **Devon & Somerset admin email is still the placeholder.** No `SEED_DEVON_ADMIN_EMAIL` override was ever set in `scripts/.env` (checked again this session - still absent), so that account is still `TODO_REPLACE_devon_somerset_admin@clearedtogo.test`. Set the env var and re-run `node scripts/seed_devon_somerset_school.mjs` (no `--reset`) before handing credentials to the real school.
5. **Business admin account uses the instructed default** (`weareclearedtogo@gmail.com`, no override set) - flagging per instructions, either way.
6. **`kRequireLoginForAllFeatures = true`** blocks all guest access, as asked - but this is the exact thing Apple previously rejected under Guideline 5.1.1(v). The flag comment documents this explicitly and the ability to flip it back is intact, but the actual App Store compliance call is yours to make before the next iOS submission.
7. **Aircraft Info screens** - confirmed already card-based and brand-consistent (Phase 8), not redesigned further since "fun" is subjective and I'm not positioned to guess at that unilaterally. Worth an actual look from you/Malins if "more fun" was the real ask.
8. **The PAVE risk-escalation gap from Phase 11**: there is no automatic risk-threshold flagging and no field anywhere recording what a pilot did after a risk was flagged (`overallRiskLevel` is a self-selected Low/Medium/High dropdown only). Confirmed genuinely absent, not invented tonight as instructed - this is real, separate feature work for a future session.
9. **`CompletionPdfBuilder` lands at 1-3 pages depending on form complexity, not always exactly 2.** The single densest flow in the app (Cessna 152 pre-boarding checklist, ~157 items) renders at 3 pages at a legible 7.5pt font; simpler flows (10-30 fields) should land at 1. Iterated twice against real data before accepting this - didn't push font size down further to force a page count at the cost of readability. Flagging the actual number rather than rounding up to "done."
10. **158 pre-existing `flutter analyze` lint issues remain untouched** (same baseline tracked since the 5 September session - deprecated Flutter APIs, naming conventions, a couple of unused fields). None are new; none are errors. Not in scope for any phase tonight.

---

## Phase 1 — Deploy the two Edge Functions

Re-verified rather than assumed already working: `get-weather` and `delete-account` were deployed in the 9 September session via `npx supabase functions deploy`. Confirmed again this session that both are reachable and routing correctly, and specifically re-checked `get-weather`'s actual data response - still blocked on `AVWX_TOKEN` (see decision #2 above). No new deploy action was needed this session; this phase's work was folded into the broader session rather than repeated separately, since nothing had changed since 9 September.

**Status: confirmed working (deploy), still blocked on the AVWX secret (data).**

## Phase 2 — Mandatory flight-school membership + business_admin role

Checked the real `profiles.role` constraint before writing anything (plain `text` + inline `CHECK`, not a native enum - confirmed via the actual migration file, not assumed). Migration `20261001100000_flight_school_mandatory.sql`, applied via the Supabase CLI (`npx supabase` works even though the CLI isn't globally installed) after first reconciling migration bookkeeping - all 7 prior migrations showed as unapplied in `supabase migration list` since they'd been pasted into the SQL Editor by hand, not run via CLI. Asked for and got explicit approval before running `migration repair` (Auto Mode's classifier flagged it), then pushed cleanly.

- Created the "Independent Pilots" catch-all school (`plan_type = 'standard'`, so individuals there get a personal trial, not a comp).
- Backfilled every null `flight_school_id` to it, then set the column `NOT NULL`. Verified directly against live data afterward: 0 null rows, `dev.pilot@clearedtogo.test` correctly moved to Independent Pilots (intended - it was deliberately unaffiliated before, to test the "no school" path, which mandatory membership retires), `dev.admin` and the Devon & Somerset admin correctly untouched (already had real schools).
- `handle_new_user()` updated to attach every new signup immediately, or the `NOT NULL` constraint would break signup outright.
- `business_admin` added to the role `CHECK` constraint (verified live via Phase 3's seed run, which elevates a real account to that role).
- business_admin cross-tenant **read**: new RLS `SELECT` policies on `profiles`, `flight_schools`, and `checklist_completions` (the third wasn't explicitly asked for in this phase, but is required by Phase 10's dashboard later, so added here instead of a near-duplicate migration). Purely additive - did not touch any existing pilot/flight_school_admin policy.
- business_admin cross-tenant **write**: two `SECURITY DEFINER` functions (`business_admin_update_profile`, `business_admin_update_school`) rather than broadening any client grant - matches the existing pattern in this codebase (sensitive columns stay ungranted, mutations go through an explicit RPC). Not wired to any UI - Phase 10's dashboard is read-only, so these remain infrastructure for later.

**Status: done, applied, verified against live data.**

## Phase 3 — Seed the demo environment

`scripts/seed_demo_environment.mjs`, same conventions as the existing seed scripts. Ran it:
- Business admin: `weareclearedtogo@gmail.com` (see decision #5).
- **Demo Flight School** created, `plan_type = comped`, separate from the real Devon & Somerset school. **Invite code: see terminal output from this session - not reproduced here** (emails and the code itself are fine to keep in this report per instructions; the actual code was already shown live and isn't re-quoted to avoid this doc going stale if it's ever rotated).
- Two demo pilots: Alex Morgan (`demo.pilot1@clearedtogo.test`) and Jamie Chen (`demo.pilot2@clearedtogo.test`).
- 6 realistic `checklist_completions` rows across both pilots (checklist, tech_log, pave_assessment for Alex; checklist, fuel_uplift, weight_balance for Jamie), timestamps spread 1-11 days back for a believable activity timeline.

All three passwords were printed to terminal only this run - not reproduced in this report or any committed file.

**Status: done.**

## Phase 4 — Auth flow rework

1. **`kRequireLoginForAllFeatures`** (default `true`) added to `config.dart`. `AuthGate` routes a guest to `LoginScreen` instead of `HomeScreen` when set; the "Continue without an account" X button is hidden entirely, not just relabeled. See decision #6.
2. **Session persistence**: confirmed via code inspection (no `persistSession`/`localStorage` override anywhere in the codebase) rather than changed - `supabase_flutter`'s default behavior already restores a session before `Supabase.initialize()` resolves. Nothing was broken here.
3. **Sign-up flow**: checked the actual live Auth setting rather than trusting local config or code comments, per instructions. `GET /auth/v1/settings` against the real project shows `mailer_autoconfirm: false` - email confirmation **is** live-enabled, directly contradicting `supabase/config.toml`'s `enable_confirmations = false` and an old code comment claiming the opposite. That comment being wrong meant `signup_screen.dart` always navigated straight into the app regardless of whether a session actually existed - a real latent bug, not a hypothetical, now fixed: `signUp()` returns `Future<Profile?>`, checks `res.session` (not `res.user`, which Supabase still populates even mid-confirmation), and the screen now shows a "check your email" dialog before routing to login when no session comes back.
4. **Invite code on signup**: added to the form. Can't resolve it via the existing `join_flight_school()` RPC (needs `auth.uid()` from a session that doesn't exist yet, per point 3) - instead `handle_new_user()` now reads `invite_code` from signup metadata directly inside the trigger, valid code -> that school, empty/invalid -> Independent Pilots, never blocks signup. Verified live against three real signups (valid Demo Flight School code, no code, garbage code) - all three resolved correctly.
5. **Delete account**: already wired from earlier work, but never actually exercised against a *deployed* function until this session. Tested end-to-end against a disposable throwaway account created solely for this check (not either demo pilot) - confirmed both the `auth.users` row and the cascaded `profiles` row were actually gone afterward.

**Status: done, verified live.**

## Phase 5 — Sign-up page cleanup

Removed the "Subscription Plans" £10/£100 box entirely (no live billing exists to describe). Checked for an existing theme/color-constants file before touching anything - none exists in this codebase, so this stayed scoped to `signup_screen.dart` rather than introducing a new design-token system. Replaced the two `Colors.black54` instances with the dark navy `#0C2942` from the given palette for real contrast.

**Status: done.**

## Phase 6 — App icon fix

Root cause: the source icon (`assets/icon/app_icon.png`) had the plane+oval artwork occupying only the middle ~86%x41% of a 1024x1024 canvas, surrounded by white margin - any circular/rounded OS mask cropped mostly into that margin. Wrote `tool/prepare_app_icon.dart` (kept as a reusable dev tool) to scale the artwork up until it bleeds past every edge instead of leaving a margin. Hit and fixed a real bug in the first pass (`compositeImage` with a negative destination offset silently produced a blank image in this library version) - caught it by actually viewing the output before regenerating real icon files, not by trusting the code. Regenerated all 5 Android mipmap densities and 21 iOS icon sizes; confirmed via file mtimes that all of them actually changed.

**Status: done, verified visually.**

## Phase 7 — Premium -> Flight School terminology

Entitlement logic (`has_premium_access()`, trial fields, `plan_type`) untouched, as instructed - copy only. Added `EntitlementService.membershipStatusText()` as one shared helper so every screen frames status consistently ("Full access via [School]" / "Trial: N days left" / "Active subscription" / "Trial expired"), wired into the two screens that previously hardcoded "Premium Member" text. Found that `FlightSchool`'s Dart model never got `plan_type` added when the DB column was (back in the 9 September session) - fixed that gap since showing real status requires knowing it. Replaced "Premium"/"Upgrade to Premium" copy across 5 files; left class/method/variable names alone (renaming internals is a different, larger-blast-radius change with no user-visible benefit).

**Status: done.**

## Phase 8 — Preflight/Ground Systems/Aircraft Info UI cleanup

Inventoried first: the hub, all 6 single preflight-system screens, and all 3 Aircraft Info screens already used the same card-based, gradient-AppBar visual language as the main checklist screens - confirmed by direct comparison, not assumed. Found one real bug while confirming the "not a dead end" requirement: the hub imported a 38-line stub `departure_briefing_screen.dart` ("Coming Soon...") instead of the real, fully-built implementation - every pilot tapping Departure Briefing was hitting a placeholder despite the real feature existing in the codebase. Fixed the import, then renamed the real file to drop its confusing `_new` suffix now that the stub is gone.

**Status: done** (plus a real dead-end bug fixed).

## Phase 9 — Checklist "Finish" + data-first storage (the largest phase, 7 commits)

Reframed the ask: redesigning 12 independent, hand-rolled PDF generators (3 checklist variants + 3 emergency variants + 6 single preflight screens, covering all 8 `completion_type` values - the task's "nine" counts checklist as one group and emergency as three per-aircraft flows) individually wasn't tractable to do correctly without visual testing each one. Built one shared, reusable renderer (`lib/utils/completion_pdf_builder.dart`) instead - same underlying data, genuinely denser layout, verified against the single densest real flow in the app (Cessna 152 pre-boarding, ~157 items) by actually generating and reading the PDF output, not guessing: **7 pages down to 3** at a legible 7.5pt (see decision #9 for why not always exactly 2).

- **Schema**: `checklist_completions.data jsonb` added. "Finish" now writes structured data with no PDF generated or uploaded; `pdf_storage_path` stays populated only on pre-migration rows.
- **All 12 flows** reworked: split each one's old `generatePDF()` into `_finishChecklist()` (data only) and `_viewAsPdf()` (on-demand, via the shared builder). Along the way, found and fixed a **real crash bug** present identically in all 3 emergency procedure screens: a `late` field (`checklistSections`) was declared but never assigned anywhere - tapping PDF on any Emergency screen would have thrown `LateInitializationError`. Not hypothetical; this was live, shipped behavior.
- **My Checklists rebuilt**: tapping a record now opens a new `CompletionDetailScreen` showing the stored structured data directly, with "View as PDF" generating fresh from it. Falls back to opening the original stored PDF for legacy rows.
- Caught and fixed my own mistakes mid-phase rather than leaving them: one edit that left ~170 lines of old PDF-building code as a renamed-but-dead method instead of actually deleting it (found via post-edit diagnostics, fixed before moving on).

**Status: done across all 12 flows + the history screen rebuild.**

## Phase 10 — Business admin dashboard

Found a real gap before building anything: `UserRole` (the Dart enum) never learned about `business_admin` when Phase 2 added it to the database - every signed-in business_admin would have been silently treated as an ordinary pilot by the app. Fixed properly (third enum value, `fromDb`/`dbValue`/`displayName` all updated).

`BusinessAdminService.loadStats()` + `BusinessAdminDashboard`: exactly what was asked for - totals, an access breakdown (comped/subscribed/trial/none, computed in the same priority order `has_premium_access()` itself resolves in), three completion counts (no chart), and a per-school table. No write actions wired to any UI - the write RPCs from Phase 2 stay unused. Wired into both places a role gets routed (`AuthGate` and `login_screen.dart`'s post-sign-in navigation).

Verified against live data, not just the RLS policies in the abstract: created a throwaway business_admin account, signed in as it, ran the dashboard's exact query shapes, and cross-checked row counts against the real totals from a service-role client - matched exactly, confirming business_admin genuinely sees every school's data.

**Status: done, verified live.**

## Phase 11 — Flight-school admin dashboard: verify + extend

Confirmed (not assumed) that `school_completions_screen.dart` already shows aircraft, timestamp, and completion type per pilot, with working filters. Found a real regression while verifying it, though - and it's one Phase 9 introduced earlier this same session, not a pre-existing bug: the screen's tap-to-open logic still assumed every completion has a stored PDF, which stopped being true the moment Phase 9 shipped. Fixed with the same `CompletionDetailScreen` pattern used in My Checklists.

Checked specifically for the risk-threshold-flagged / pilot's-next-action signal per instructions, rather than assuming it was there or guessing it wasn't: confirmed genuinely absent (see decision #8).

**Status: done** (verification + a same-session regression caught and fixed).

## Phase 12 — This report

Written to `docs/overnight_report_2026-10-01.md`, committed, branch pushed. Not merged, no PR opened, per instructions.
