# ClearedToGo — Supabase setup & deploy runbook

Everything you (the maintainer) need to run to take the migration live.
Reference for *what* it all does: [`supabase_migration.md`](./supabase_migration.md).

The dev machine used for the migration had **no** Supabase CLI and **no**
Node, so none of the below has been executed — the code is written and
`flutter analyze` is clean, but you run these once.

---

## 0. Prerequisites

```bash
# Supabase CLI (pick one)
npm  i -g supabase
# or: scoop install supabase        (Windows)
# or: brew install supabase/tap/supabase   (macOS)

supabase --version        # sanity check
node --version            # >= 18, for the seed script

supabase login            # opens browser, pastes an access token
```

You need, from the Supabase dashboard → Project Settings → API:

- **Project URL** — `https://<ref>.supabase.co`
- **`anon` / publishable key**
- **`service_role` key** — secret

And your **project ref** (`<ref>` above, also in Settings → General).

---

## 1. Link the repo to your project

From the repo root (the folder containing `supabase/`):

```bash
supabase link --project-ref <YOUR_PROJECT_REF>
```

`supabase/config.toml` is already committed. This writes local link state
under `supabase/.temp/` (gitignored).

*(Optional, full local stack for offline dev — needs Docker:)*
```bash
supabase start            # local Postgres + Studio + Auth + Storage
supabase db reset         # applies migrations + any seed to the LOCAL db
```

---

## 2. Apply the schema

```bash
supabase db push          # runs the 4 migrations in supabase/migrations/
```

Verify in Studio → Table editor: `flight_schools`, `profiles`,
`checklist_completions` exist; Storage has a **private** bucket
`checklist-pdfs`; Database → Policies shows the RLS policies from
`20260903120200` / `20260903120300`.

---

## 3. Auth config

`supabase/config.toml` sets `enable_confirmations = false` for local. For the
**hosted** project also set it in the dashboard: Authentication → Providers →
Email → **Confirm email = OFF** (matches the app, which has no verification
screen). If you later want confirmations, see follow-up #6 in the migration
doc.

---

## 4. Edge Functions

```bash
# AVWX proxy — set the secret FIRST (use the real token; it never goes in code)
supabase secrets set AVWX_TOKEN=<the real AVWX token>

supabase functions deploy get-weather
supabase functions deploy delete-account
```

Notes:
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` are injected
  automatically into deployed functions on the hosted platform — you do **not**
  set those as secrets.
- `config.toml` already declares `verify_jwt = true` for `delete-account` and
  `verify_jwt = false` for `get-weather`.

Smoke tests:
```bash
# weather (no auth)
curl -s -X POST "https://<ref>.functions.supabase.co/get-weather" \
  -H "Content-Type: application/json" \
  -d '{"endpoint":"metar","icao":"EGLL","options":"info,translate"}' | head -c 300

# delete-account requires a real user JWT; test from the app's Delete Account button.
```

---

## 5. Seed dev accounts

```bash
cd scripts
npm install
cp .env.example .env
#   edit scripts/.env:
#     SUPABASE_URL=https://<ref>.supabase.co
#     SUPABASE_SERVICE_ROLE_KEY=<service_role key>
node seed_dev_user.mjs
```

Prints (passwords generated at run time, not stored anywhere else):

```
Flight school : Dev Flight School
  id / invite code
PILOT               dev.pilot@clearedtogo.test  / <generated>
FLIGHT SCHOOL ADMIN dev.admin@clearedtogo.test  / <generated>   role=flight_school_admin
```

`node seed_dev_user.mjs --reset` deletes + recreates them.

To attach the dev pilot to the school for testing the admin views (no join-UI
yet), run in Studio → SQL editor:

```sql
update public.profiles p
set flight_school_id = (select id from public.flight_schools where name = 'Dev Flight School')
where p.id = (select id from auth.users where email = 'dev.pilot@clearedtogo.test');
```

---

## 6. Flutter client env

```bash
cp .env.example .env       # repo root
#   SUPABASE_URL=https://<ref>.supabase.co
#   SUPABASE_ANON_KEY=<anon key>

flutter pub get
flutter run                # or: flutter run --dart-define-from-file=.env
```

`.env` is a bundled asset (see `pubspec.yaml`), gitignored.

---

## 7. iOS / StoreKit (Phase 4)

- Deployment target is already bumped to **15.0** (`project.pbxproj`,
  `AppFrameworkInfo.plist`, `ios/Podfile`).
- `cd ios && pod install` (on a Mac) after `flutter pub get`.
- In **App Store Connect**: create two auto-renewable subscription products,
  then put their IDs into `lib/config/config.dart`
  (`kMonthlySubscriptionId`, `kYearlySubscriptionId`) replacing the
  `TODO_REPLACE_…` placeholders.
- Add a **StoreKit configuration file** in Xcode for local purchase testing
  (Product → Scheme → Options → StoreKit Configuration), or use a Sandbox
  Apple Account.
- Set `kDisablePaywallForDev = false` in `lib/config/config.dart` to exercise
  the real purchase path.
- Replace `kPrivacyPolicyUrl` / `kTermsOfUseUrl` (or the in-app
  `PrivacyPolicyScreen`) with your real legal pages.

---

## 8. Command cheat-sheet

```bash
# schema changes: add a new file to supabase/migrations/ then
supabase db push
supabase db diff -f <name>          # generate a migration from Studio edits

supabase functions deploy <name>
supabase functions logs <name>
supabase secrets list
supabase secrets set KEY=value

cd scripts && node seed_dev_user.mjs [--reset]
```
