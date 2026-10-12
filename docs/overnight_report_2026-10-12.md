# App Store resubmission prep — 12 Oct 2026

Branch: `flight-school-accountability`. Not merged to `main`.

## Blocker — needs Thomas's attention before Phase 3/4 can finish

**The Supabase project is unreachable from this session.** `lrwqszvgikgpjhacqscb.supabase.co` (the same URL every prior session used successfully through 6 Oct) no longer resolves via DNS at all — confirmed against both the local resolver and Google's public DNS (8.8.8.8), both return "Non-existent domain," not a timeout or connection-refused. Separately, `SUPABASE_ACCESS_TOKEN` in `scripts/.env` (used for CLI/management-API access) also came back "Invalid access token" when checked. `scripts/.env` itself is unchanged and byte-clean — not a typo or stray character, checked with `xxd`.

Two independent failures (DNS to the data-plane URL, and the management-plane access token) suggests something more than a transient blip — possibilities include the project being paused long enough that Supabase reclaimed the subdomain, the project being deleted, or the access token being revoked/rotated outside this session. This needs Thomas to check the Supabase dashboard directly and report back; I didn't guess further or attempt workarounds.

**Impact**: Phase 3 (reviewer accounts, invite code, password resets) could not run at all. Phase 4's `docs/APPLE_REVIEW_NOTES.md` is written as a template with `[PLACEHOLDER]` markers instead of real values — **do not paste it into App Store Connect as-is**.

## Phase 0 — Setup ✅

Clean, on `flight-school-accountability`, in sync with origin.

## Phase 1 — Guest bypass on the sign-in page ✅

`kAllowGuestBypass` added to `config.dart` (true on iOS via `defaultTargetPlatform`, false elsewhere). Sign-in screen shows "Continue without an account" under the main button when the flag is true. Guest state lives in `SupabaseAuthService.isGuestMode`, checked by `AuthGate` and the global signed-out listener so a guest isn't bounced back to `/login`.

Found and fixed a real bug along the way: every one of the 12 completion-recording flows called `SupabasePdfService().recordCompletion(Data)()`, which already silently returned `null` when signed out — but every caller then showed a "saved!" SnackBar regardless, a **false positive** for a guest who'd just lost their data. Added a shared `requireSignInToSave()` guard (`lib/widgets/sign_in_prompt.dart`) and wired it into all 12 flows before the save call. Also added a sign-in guard to `flight_school_membership_screen.dart`, which had none (My Checklists and Account Details already had one).

**Not tested on a device** — no iOS/Android simulator or emulator is available in this environment (`flutter devices` shows only Windows desktop and Edge web). Verified via `flutter analyze lib` and code review only. Please verify the guest flow on real hardware (or at least a simulator) before relying on it.

## Phase 2 — Build config for Codemagic ✅ (needs your setup in the Codemagic UI)

**`codemagic.yaml` did not exist anywhere in this repo.** There was nothing to read or patch, so this phase created it from scratch instead. It can't be test-executed from this environment (no Codemagic access here) — treat it as a reviewed starting point, not a guaranteed-working pipeline; expect to iterate on the first real build.

**Codemagic UI setup needed before the first build:**
1. Environment variable group named `supabase_client`, containing `SUPABASE_URL` and `SUPABASE_ANON_KEY` (mark both secret). The build writes these into a `.env` file before `flutter build ipa`, since the app loads them from a bundled `.env` at runtime (`lib/config/env.dart` via `flutter_dotenv`) and `.env` is gitignored, so a fresh Codemagic checkout has none.
2. An App Store Connect integration (Team settings → Integrations → Developer Portal, using an App Store Connect API key), named `codemagic_appstore_connect` in the yaml — rename either side to match if you call it something else.

`pubspec.yaml` version bumped `1.0.1+9` → `1.0.1+100`. No `codemagic.yaml` existed to override the build number, and the one just added doesn't either — it builds with whatever's in `pubspec.yaml` as-is.

App icon: `assets/icon/app_icon.png` is 1024×1024, PNG color type 2 (RGB, no alpha) — already compliant. Checked all 21 files in `ios/Runner/Assets.xcassets/AppIcon.appiconset` the same way (parsed each PNG's IHDR color-type byte directly — no PIL/ImageMagick available here) — all RGB, no alpha, nothing to flatten or regenerate.

`CFBundleDisplayName` in `ios/Runner/Info.plist` is already "ClearedToGo".

## Phase 3 — Reviewer accounts and credentials ❌ blocked

Could not run at all — see the blocker above. No accounts were created, no passwords were reset, the Demo Flight School invite code was not read. `docs/DEV_CREDENTIALS.md` on disk is unchanged from the 6 Oct session (still just the 3 original dev accounts) — it was **not** updated this session, and I'm not printing it as if it reflects today's work. If Supabase access comes back and those 3 accounts' passwords are still what they were, that old file is still presumably accurate, but that's an assumption, not something re-verified today.

## Phase 4 — Apple paste-ready files ⚠️ written as templates, not real

Both files created in `docs/` and added to `.gitignore` (never committed):
- `docs/APPLE_REVIEW_NOTES.md` — template only, every credential and the invite code is a `[PLACEHOLDER]`. Starts with a loud warning not to paste it into App Store Connect until it's filled in with real values from a successful Phase 3 re-run.
- `docs/APPLE_RESUBMIT_CHECKLIST.md` — the full manual checklist, doesn't depend on live Supabase data so it's complete and usable now. Opens with a note pointing at the blocker above.

## Phase 5 — Finish

Code changes committed (this commit + the Phase 1/2 commits before it) and pushed. No credential or notes files committed — `docs/DEV_CREDENTIALS.md`, `docs/APPLE_REVIEW_NOTES.md`, and `docs/APPLE_RESUBMIT_CHECKLIST.md` are all gitignored.

**Needs Thomas's decision/action:**
1. Check the Supabase dashboard — is the project paused, deleted, or has the URL/ref changed? Is the access token in `scripts/.env` still valid, or does it need regenerating?
2. Once that's resolved, re-run Phase 3 (reviewer account creation, invite code read, password resets) and Phase 4's real-values pass on `APPLE_REVIEW_NOTES.md`.
3. Set up the two Codemagic UI items listed in Phase 2 before starting a build.
4. Verify Phase 1's guest-bypass flow on an actual iOS device/simulator — it was only verified by static analysis this session.
