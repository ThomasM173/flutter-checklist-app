# Overnight Fix Session — 10 September 2026

Branch: `overnight-fixes` (pushed, not merged, not a PR — per instructions).
Commits this session: `d890038` .. (this report's commit).

## Needs a decision from Thomas

1. **Phase 1–2 (Edge Function deploy) skipped entirely** — `SUPABASE_ACCESS_TOKEN` wasn't present in `scripts/.env` when this session started (checked the variable name only, per the never-print-`.env` rule; also checked for case-variant naming, nothing found). Per your instructions, I didn't attempt a workaround. To unblock next time: Supabase Dashboard → Account → Access Tokens → generate one → add `SUPABASE_ACCESS_TOKEN=sbp_...` to `scripts/.env` before the next session starts.
2. **`main` divergence: genuinely needs a look, not safe to auto-resolve.** This is the big one — see Phase 3 below for full detail. Two files (the old PDF system) are confirmed safe for `overnight-fixes` to win. But 5 *live, actively-used* screens have real conflicting changes: `origin/main` contains a deliberate `SafeArea` wrapping fix (status bar/notch overlap) applied consistently across `flight_conditions_screen.dart`, `home_screen.dart`, and `learning_game_screen.dart`, plus genuine Flutter-deprecation fixes in `fuel_uplift_screen.dart` and `weight_balance_screen.dart`. None of that is in `overnight-fixes`. A naive merge resolution that just picks `overnight-fixes` for everything would silently lose that work. This needs you to actually look at it, not a script.
3. **Devon & Somerset admin email is still the placeholder** (carried over from 9 Sept, untouched this session — not in scope for tonight's phases). Still `TODO_REPLACE_devon_somerset_admin@clearedtogo.test`, invite code still `EB769BEE`, still shouldn't be handed to the school yet.
4. Nothing in Phase 4 needed a "can't verify" note — I confirmed every claim in the rewritten `PREMIUM_INTEGRATION_GUIDE.md` directly against the current source before writing it. One thing worth your attention there specifically, though not a blocker: **Android/Google Play Billing is genuinely unbuilt**, not "coming soon" as the old doc implied — `IapService._verify()` only understands Apple's StoreKit 2 format. If Android release is on your near-term roadmap, that's real work, not a config flip.

---

## Phase 0 — Setup

Clean tree, already on `overnight-fixes`, pulled (already up to date). Checked `scripts/.env` for `SUPABASE_ACCESS_TOKEN` — not present. Per instructions, skipped Phase 1–2 and went straight to Phase 3.

**Status: done. Phase 1–2 skipped (token missing).**

## Phase 3 — Investigate the `main` divergence

**Investigation only, no merge/resolve performed**, per instructions.

First had to correct my own approach: my local `main` branch ref was stale (never pulled since this repo was cloned), so `git log main ^overnight-fixes` found nothing — the real comparison needed to be against `origin/main`. Once corrected, found the divergent commit: `56d8b82 "AND16 UPDATED"` (author `djc242`, 6 Sept), **22 files**, not limited to PDF files despite how the previous session's report framed it.

Instead of manually diffing 22 files by eye, simulated the actual 3-way merge non-destructively: `git merge-tree --write-tree overnight-fixes origin/main` (touches no refs, no working tree). Result: **7 real conflicts**, in two very different categories.

### Safe — matches the original PDF framing exactly
- `lib/screens/flight_school/pdf_library_screen.dart` (modify/delete)
- `lib/services/pdf_storage_helper.dart` (modify/delete)

Both confirmed deleted in `overnight-fixes`' Phase 0 checkpoint (5 Sept). `origin/main`'s changes to them are trivial Flutter-deprecation fixes (`Key? key` → `super.key`, `DropdownButtonFormField`'s `value:` → `initialValue:`). Grepped the current `overnight-fixes` `lib/` tree for `PdfLibraryScreen`, `PdfStorageHelper`, and both filenames — zero remaining references anywhere. **Safe for `overnight-fixes` to win these two.**

### Not safe — real content conflicts in 5 live screens
- `lib/screens/flight_conditions_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/learning_game_screen.dart`
- `lib/screens/preflight_systems/fuel_uplift_screen.dart`
- `lib/screens/preflight_systems/weight_balance_screen.dart`

Read the actual diff content on both sides for every one of these (not just line counts):

- **`origin/main`** contains a consistent, deliberate pattern across the first three: wrapping `body: <Widget>` in `body: SafeArea(child: <Widget>)`. That's a real UI fix (content sitting under the status bar / notch), not cosmetic. The other two have genuine Flutter-deprecation fixes (`DropdownButtonFormField value:` → `initialValue:`, `Switch activeColor` → `activeThumbColor`) plus an unused-import removal (`weather_boundaries.dart`) in `flight_conditions_screen.dart`.
- **`overnight-fixes`**' side of the exact same 5 files is exclusively `dart format` reflow from 5 Sept's Phase 5 — confirmed by reading the diffs, not inferring from size (e.g. `fuel_uplift_screen.dart` shows 383 changed lines on this side but zero semantic difference, purely re-wrapping).

A naive "`overnight-fixes` wins" resolution would **silently discard the `SafeArea` fix and both deprecation fixes**. That's the wrong call to make unilaterally, which is why this is flagged as "needs a look" rather than resolved here.

15 other files in the commit auto-merged cleanly (no line-range collision) — spot-checked several (`app_drawer.dart`, `local_checklist_repository.dart`, `cessna_152_checklist.dart`, `weather_service.dart`) and found the same class of small, real cleanups (unused imports, `Container` → `SizedBox`, a redundant ternary). Worth noting: `app_drawer.dart`'s `origin/main` edit removes an import (`paywall_screen.dart`) from code that `overnight-fixes` has since substantially rewritten as part of the Supabase migration — "merged cleanly" here just means no line collision, not that the change is still meaningful in the new architecture. The three `android/` Gradle files (`build.gradle.kts`, `gradle-wrapper.properties`, `settings.gradle.kts`) also auto-merged cleanly — **not inspected in detail**, flagging as unchecked rather than claiming they're fine.

**Verdict: NEEDS A LOOK.** Recommendation for when you do resolve it: take `overnight-fixes` wholesale for the 2 PDF files, but for the 5 real-conflict screens, don't just pick a side — the `SafeArea`/deprecation fixes on `origin/main`'s side should probably be re-applied on top of `overnight-fixes`' migration work, not discarded. Not performed here, per instructions.

**Status: done (investigation only).**

## Phase 4 — Rewrite the stale Premium Feature Integration Guide

Found via `grep -rl "kDisablePaywallForDev" --include="*.md" .` — also matched `docs/supabase_migration.md` and `docs/supabase_setup.md`, both already current; only `PREMIUM_INTEGRATION_GUIDE.md` was stale.

The doc predated the Supabase migration entirely: wrong package name throughout (`flutter_application_1`, not `clearedtogo`), referenced a deleted `AuthService` class, claimed premium state lives in `SharedPreferences`, and never mentioned `kIapEnabled` — only knew about `kDisablePaywallForDev`.

Verified the real current implementation before writing anything (didn't guess):
- `config.dart`: both `kDisablePaywallForDev` (dev bypass) and `kIapEnabled` (launch flag) exist and answer different questions.
- `entitlement_service.dart` / `supabase_auth_service.dart`: premium status is `Profile.isPremium`, populated by a `has_premium_access()` Supabase RPC call on every profile load — not `SharedPreferences`.
- `premium_feature_wrapper.dart`: still fully functional, but grepped for `PremiumFeatureWrapper(` call sites — none outside its own definition file. Documented as available-but-unused rather than implying it's wired into a real screen.
- `premium_pricing_screen.dart`: routes to the real `PaywallScreen` when `kIapEnabled` is true (from this session's earlier entitlement work) — no longer the dead stub the old doc's testing section described.
- `iap_service.dart` + `pubspec.yaml`: only `in_app_purchase` + `in_app_purchase_storekit` (iOS/StoreKit) as direct dependencies. Grepped `lib/` for `GooglePlay`/`BillingClient`/`in_app_purchase_android` usage — zero hits. `IapService._verify()` decodes StoreKit 2's JWS format specifically, which wouldn't work correctly against Google Play's receipt format. Documented Android billing as genuinely unbuilt rather than leaving the old doc's "Future Integration: Google Play Billing" section implying it's simply next up.

Rewrote Configuration, Usage, Testing, and Architecture to match. Caught and corrected my own over-reach mid-task: I'd initially deleted the "Examples in Current App" section entirely since it wasn't one of the three sections your instructions named — but it wasn't factually wrong (explicitly hypothetical "Could Be Premium" framing), so removing it was scope creep on my part. Restored it unchanged.

Nothing in the current architecture was unclear enough to need a "can't verify" note in the doc — everything written was confirmed directly against the current source first.

**Status: done.**

## Phase 5 — This report

Written to `docs/overnight_report_2026-09-10.md`, committed, branch pushed. Not merged, no PR opened, per instructions.
