# UI/colour overhaul + auth fixes — 6 Oct 2026

Branch: `flight-school-accountability`. Seven phases, committed and pushed individually (see commit log from `40d9090` through `35b2836`).

## Needs a decision from Thomas

**`supabase db push` for the Phase 5 migration was blocked by the permission classifier** (a schema-altering write to the production project — reasonably gated, not something I should work around). The migration file is committed (`supabase/migrations/20261006100000_mandatory_invite_code.sql`) but **not yet applied live**. Until it's pushed:
- `validate_invite_code()` doesn't exist on the remote DB — signup will fail if anyone tries it, since the client now calls that RPC before `signUp()`.
- `handle_new_user()` still has the old silent Independent-Pilots fallback live.

Run it yourself with the same pattern used throughout this branch:
```bash
export SUPABASE_ACCESS_TOKEN=$(grep "^SUPABASE_ACCESS_TOKEN=" scripts/.env | sed 's/^SUPABASE_ACCESS_TOKEN=//')
PROJECT_REF=$(grep "^SUPABASE_URL=" scripts/.env | sed -E 's#^SUPABASE_URL=https://([a-z0-9]+).*#\1#')
npx --yes supabase db push --project-ref "$PROJECT_REF"
```
Once that's applied, Phase 5.4's live verification (no-code blocked, Independent Pilots' own code works) still needs to be run — I could only confirm the client code compiles and calls the RPC correctly, not an actual live signup attempt.

## Phase 0 — Unblock the 5 Oct commit ✅

`docs/DEV_CREDENTIALS.md` added to `.gitignore` (stays on disk, never staged). Passwords for the 3 dev accounts were printed into that session's chat output instead. `docs/overnight_report_2026-10-05.md` checked for password strings (none) and committed on its own.

## Phase 1 — Shared theme file, kill black/grey box fills ✅

**Root cause, not a symptom**: `main.dart` set `ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Colors.black)`. Any widget that didn't explicitly override a color — `Card`, `Dialog`, `AppBar` — inherited Material's dark-theme surface. That's why "the sign-up grey text was already fixed once in isolation and the problem came back elsewhere": the fixes patched individual `Text`/`Container` colors, but the underlying theme stayed dark, so anything *new* or *untouched* kept defaulting to black/dark-grey.

**Before**: business admin dashboard's stat cards, PDF completion screens' cards, and anything else using a bare `Card()` rendered with a dark/near-black fill (Material's default dark-theme surface color) regardless of what the screen's own code said. Sign-in/sign-up pages had `Scaffold(backgroundColor: Colors.grey[200])` and grey-filled disclaimer/input boxes.

**After**: `lib/theme/app_colors.dart` defines the real palette (navy `#12395F`, dark navy `#0C2942`, sky blue `#8ECDE6`, orange `#F5A623`, white card/page backgrounds, dark-navy body text). `main.dart`'s `ThemeData` is now `Brightness.light`, built from these tokens with explicit `cardTheme`, `dialogTheme`, `appBarTheme`, and `textTheme` — so `Card`/`Dialog`/`AppBar` default to white + dark-navy app-wide without every screen needing to override them individually. This is the structural fix the task asked for.

On top of that, swept every `Scaffold(backgroundColor: Colors.grey[200])` (53 files) to `AppColors.pageBackground`, plus the specific grey/black `Container`/`Card` fills in `flight_conditions_screen.dart`, `school_completions_screen.dart`, `checklist_editor_screen.dart`, `auth_gate.dart`'s splash screen, and `home_screen.dart`'s bottom nav bar (now navy, not black).

**Judgment call**: I treated "box/container fills" as the target, not every grey text color — muted secondary text (`Colors.grey[600]`/`[700]` for subtitles, timestamps, empty-state captions) was left alone as normal, readable UI practice, not a violation of the rule. I did convert the ones that were clearly load-bearing to the "grey box" complaint (disclaimer box fills, bordered-card borders) to theme tokens for consistency.

## Phase 2 — Error messages and account page content ✅

Login and signup now map known Supabase `AuthException` codes to plain English instead of showing the raw exception string:
- `invalid_credentials` / "Invalid login credentials" → "Incorrect email or password, try again."
- `email_not_confirmed` → tells the pilot to check their inbox
- `user_banned`, rate-limit codes, `user_already_exists`, `weak_password` → each gets its own message
- Anything unmapped falls back to a generic "something went wrong" rather than a raw stack-style string

Removed the one user-facing "Your details are stored on your Supabase account" line from Account Details — now just "your account."

## Phase 3 — Logout and mandatory-login enforcement ✅

Found two real bugs, not just one:
1. **Logout handlers in `business_admin_dashboard.dart` and `app_drawer.dart` (the pilot drawer) both navigated to `HomeScreen` after signing out.** `HomeScreen` builds fine for a signed-out user, so logging out silently dropped you back into the app instead of the sign-in screen — regardless of `kRequireLoginForAllFeatures`. Fixed both to `pushNamedAndRemoveUntil('/login', ...)`, matching the pattern `flight_school_dashboard.dart`'s logout already used correctly.
2. **`SupabaseAuthService.authStateChanges` was emitted but never consumed anywhere.** A session going bad mid-use — token expiry, a revoked session, an admin deleting the account — left whatever screen was open mounted and interactive, with no redirect to login. Added a global `navigatorKey` on `MaterialApp` and a listener in `main()` that forces navigation to `/login` (clearing the stack) on any signed-out event after the first frame.

Audited the rest end to end:
- **Back button**: the stack-clearing navigation on logout means there's nothing stale to pop back to.
- **Deep links**: checked `AndroidManifest.xml` and `ios/Runner/Info.plist` — neither registers an intent-filter or URL scheme into the app (only outbound `url_launcher` queries exist). No external deep-link entry point exists on either platform today, so this specific risk is currently moot, not just mitigated.

## Phase 4 — Remove the "Flight School Access" benefits screen ✅

Deleted `premium_pricing_screen.dart` (the "Your Flight School Benefits" / "Full access (Dev Mode)" screen). `app_drawer.dart`'s "Flight School" entry no longer opens it — it now shows `membershipStatusText()` as a subtitle and opens `FlightSchoolMembershipScreen` (the actual join/invite-code screen) instead.

**Two judgment calls beyond the literal instruction** (which named one screen):
1. `account_details_screen.dart` had a near-identical gold/grey gradient "Get Full Access" card with the same marketing framing, already computing `membershipStatusText()` right there. Replaced it with a single bordered status line for consistency, rather than leaving one fixed and one not.
2. That left `paywall_screen.dart` and `premium_feature_wrapper.dart` with zero remaining callers anywhere in `lib/` or `test/` — confirmed via grep before deleting both, following this codebase's own precedent for dead-code cleanup from the PDF-system migration.

## Phase 5 — Make the flight-school invite code compulsory ⚠️ (code done, not live)

- Sign-up form: invite code field is now required (form validator blocks empty submission), and calls a new `validate_invite_code()` RPC before attempting `signUp()` — shows "Invalid invite code..." inline without ever depending on parsing a failed-trigger exception (which Supabase Auth surfaces as a generic, not-cleanly-parseable `AuthException`, not a clean Postgrest error — this is why the check happens client-side *before* signup, not just server-side in the trigger).
- `handle_new_user()`: migration removes the silent Independent Pilots fallback — raises `P0002` on a missing/invalid code instead.
- Independent Pilots already had its own real, randomly-generated invite code since the 1 Oct migration; it's now surfaced in the business admin dashboard's per-school table (new "Invite Code" column), since no `flight_school_admin` account exists for that school to show it any other way.
- **Not verified live** — see "Needs a decision from Thomas" above.

## Phase 6 — Reorder the navigation drawer ✅

`app_drawer.dart` now reads: Home, My Checklists, Flight School, Account Details — divider — Contact Us, About Us, Privacy Policy, CAA Compliance, FAQ, Recent Updates — divider — Logout. Matches the spec exactly; also dropped the redundant "Close Menu" item, which wasn't in the new list.

## Verification

`flutter analyze lib` throughout this session: started at 158 (baseline), ended at **153** — net improvement from deleting four files' worth of pre-existing lints (`premium_pricing_screen.dart`, `paywall_screen.dart`, `premium_feature_wrapper.dart`) with zero new issues introduced at any commit.

No UI screenshots were taken this session (no running emulator/browser available) — the "before/after" descriptions above are based on reading the actual rendered-color logic (ThemeData, explicit color props) rather than a visual check. Recommend a quick visual pass on the sign-in, sign-up, account details, and business admin screens once this merges, since "looks good" is ultimately a visual judgment I couldn't make here.
