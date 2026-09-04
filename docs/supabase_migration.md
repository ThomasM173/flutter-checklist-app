# ClearedToGo — AWS → Supabase migration

Status: **code-complete, not yet run against a live project.** This document is
the reference for the schema, the auth/PDF/weather/IAP flows, and every
secret involved. Companion: [`supabase_setup.md`](./supabase_setup.md) for the
step-by-step "get it running" commands. The pre-migration AWS inventory is in
[`aws_usage_map.md`](./aws_usage_map.md).

---

## 1. Schema

All objects live in `public` unless noted. Migrations under
`supabase/migrations/` (apply with `supabase db push`):

| File | Contents |
|---|---|
| `20260903120000_init_schema.sql` | tables + indexes |
| `20260903120100_functions_triggers.sql` | RLS helpers, new-user trigger, invite-code RPCs |
| `20260903120200_rls_policies.sql` | grants + RLS policies |
| `20260903120300_storage.sql` | `checklist-pdfs` bucket + storage policies |

### 1.1 `flight_schools`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | `gen_random_uuid()` |
| `name` | `text` not null | |
| `address`, `phone`, `email` | `text` | optional contact info |
| `invite_code` | `text` not null **unique** | 8-char code a pilot enters to join |
| `created_at` | `timestamptz` | `now()` |

**Rationale.** The old `LocalAuthRepository` implied schools only through a
single hardcoded `flightSchoolId` (`demo-school-001`) on one demo admin — no
real school entity, and pilots were **never** assigned one. We modelled a
proper multi-tenant table. One rotatable `invite_code` per school (rather than
a separate `invites` table) is enough at this scale and keeps the join flow to
a single RPC. Rows are created **only** by the seed script / service role.

### 1.2 `profiles` (1:1 with `auth.users`)

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK → `auth.users(id)` `on delete cascade` | |
| `full_name` | `text` | from signup metadata |
| `role` | `text` not null default `'pilot'` | check: `pilot` \| `flight_school_admin` |
| `flight_school_id` | `uuid` → `flight_schools(id)` `on delete set null` | |
| `license_number` | `text` | carried over from the old on-device profile |
| `home_base` | `text` | carried over from the old on-device profile |
| `subscription_status` | `text` not null default `'free'` | check: `free` \| `premium` |
| `subscription_product_id` | `text` | StoreKit product id of the active sub |
| `subscription_expires_at` | `timestamptz` | best-effort expiry from the StoreKit 2 transaction |
| `created_at` | `timestamptz` | `now()` |

**Rationale / decisions**

- **`role` is never set by the client.** `handle_new_user()` always writes
  `'pilot'`; signup metadata is untrusted. Admins are elevated by the seed
  script (service role). Column-level `UPDATE` on `role` is revoked from
  `authenticated`.
- **`flight_school_id` is never set directly by the client** either — column
  `UPDATE` is revoked. It changes only through `join_flight_school()` /
  `leave_flight_school()` (both `SECURITY DEFINER`). This is what makes the
  "admin sees only their own school's pilots" boundary trustworthy: a pilot
  can't attach themselves to an arbitrary school.
- **`license_number` / `home_base`** kept because `account_details_screen`
  and the checklist-PDF header already use them. Not in the original spec but
  they're existing product data.
- **`subscription_*` columns *are* client-writable** (Guideline 3.1.2 flow
  needs it) — RLS limits the update to `id = auth.uid()`. See §5 for the
  explicit limitation this carries.

### 1.3 `checklist_completions`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | `gen_random_uuid()` |
| `user_id` | `uuid` not null → `profiles(id)` `on delete cascade` | |
| `flight_school_id` | `uuid` → `flight_schools(id)` `on delete set null` | **denormalised at completion time** |
| `aircraft_type` | `text` not null | e.g. `Cessna 152` |
| `checklist_name` | `text` not null | e.g. `Pre-boarding Checklist` |
| `completed_at` | `timestamptz` not null | `now()` |
| `pdf_storage_path` | `text` | `{user_id}/{id}.pdf` in the private bucket |
| `created_at` | `timestamptz` | `now()` |

**Rationale.** `flight_school_id` is a **snapshot** of the pilot's
`profiles.flight_school_id` at completion time, not a live FK to their current
school. So if a pilot leaves a school, the admin still sees the completions
that happened while the pilot was a member — and doesn't retroactively gain
visibility of completions from before the pilot joined. Append-only from the
client (grant is `select, insert` only).

### 1.4 RLS helper functions

`current_user_role()` and `current_user_flight_school_id()` are
`SECURITY DEFINER STABLE` functions that read `profiles` for `auth.uid()`.
They exist to break the classic recursion: an RLS policy **on** `profiles`
that needs to know the caller's role can't `SELECT` from `profiles` directly
(that re-triggers RLS). The definer functions read it once, RLS-free.

### 1.5 RLS policies

Every app table: `REVOKE ALL FROM anon, authenticated`, then grant back the
minimum.

**`profiles`** — grants: `SELECT`; `UPDATE(full_name, license_number,
home_base, subscription_status, subscription_product_id,
subscription_expires_at)`.

| Policy | Cmd | Rule |
|---|---|---|
| self read | SELECT | `id = auth.uid()` |
| admin reads own-school pilots | SELECT | caller is `flight_school_admin` AND row is a `pilot` in the caller's `flight_school_id` |
| self update | UPDATE | `id = auth.uid()` (using + with check) |

**`flight_schools`** — grants: `SELECT`; `UPDATE(name, address, phone, email)`.

| Policy | Cmd | Rule |
|---|---|---|
| members read own school | SELECT | `id = current_user_flight_school_id()` |
| admin updates own school | UPDATE | own school AND role = admin |

`invite_code` is not in the update grant → only `rotate_flight_school_invite_code()` changes it.

**`checklist_completions`** — grants: `SELECT, INSERT`.

| Policy | Cmd | Rule |
|---|---|---|
| pilot inserts own | INSERT | `user_id = auth.uid()` |
| pilot reads own | SELECT | `user_id = auth.uid()` |
| admin reads own-school rows | SELECT | caller is admin AND `flight_school_id = current_user_flight_school_id()` |

**`storage.objects` (bucket `checklist-pdfs`, private)** — path
`{user_id}/{completion_id}.pdf`; folder segment 1 = owner uid.

| Policy | Cmd | Rule |
|---|---|---|
| owner reads / uploads / updates / deletes own | SELECT/INSERT/UPDATE/DELETE | `(storage.foldername(name))[1] = auth.uid()::text` |
| admin reads own-school pilot files | SELECT | caller is admin AND folder-1 uid belongs to a `pilot` in the caller's school |

### 1.6 Functions / RPCs

| Function | Security | Purpose |
|---|---|---|
| `handle_new_user()` | definer, trigger `on_auth_user_created` on `auth.users` | insert the `profiles` row (`role='pilot'`, `full_name` from metadata) |
| `join_flight_school(p_invite_code text) → profiles` | definer, `execute` to `authenticated` | pilot self-attaches by code; rejects admins and bad codes |
| `leave_flight_school() → profiles` | definer, `authenticated` | pilot clears their `flight_school_id` |
| `rotate_flight_school_invite_code() → text` | definer, `authenticated` | admin-only; issues a fresh unique 8-char code for their school |
| `current_user_role() → text` | definer, stable | RLS helper |
| `current_user_flight_school_id() → uuid` | definer, stable | RLS helper |

---

## 2. Auth flow

Single service: **`lib/services/supabase_auth_service.dart`**
(`SupabaseAuthService`, singleton). It replaces **both** previous systems.

### The old two-system problem

`aws_usage_map.md` §1 documented two independent, non-sharing user stores:

1. `AuthService` — real Cognito users **plus** a hardcoded `Tom`/`David`
   bypass treated as a local admin.
2. `AuthServiceManager → LocalAuthRepository` — a second, SharedPreferences-only
   store for flight-school/demo accounts (`school@demo.com` / `Demo123!`).

`AuthGate` checked #2 then fell back to #1; `AuthService` wasn't even a
singleton, so screens disagreed about whether you were signed in.

### How it's resolved

Everyone — pilots and flight-school admins — is now a single Supabase Auth
account with one `profiles` row. Admin is just `profiles.role =
'flight_school_admin'`. No hardcoded credentials in the app; the demo
accounts moved into `scripts/seed_dev_user.mjs` (service role, run outside
Flutter, prints freshly generated passwords). One singleton service; `init()`
is idempotent and called once in `main()`.

### Operations

| Action | Method | Implementation |
|---|---|---|
| Sign up | `signUp(email, password, {fullName, acceptedTerms})` | `auth.signUp` with `data: {full_name}`. Email confirmation is **disabled** (`supabase/config.toml` → `enable_confirmations = false`), so a session comes back immediately. `signup_screen.dart` gained an optional Full Name field; the old `email_verification_screen.dart` was deleted. |
| Sign in | `signIn(email, password)` | `auth.signInWithPassword`, then loads the profile. `login_screen.dart` lost its two-system fallback. |
| Sign out | `signOut()` / `logout()` alias | `auth.signOut()` |
| Delete account | `deleteAccount()` | invokes the **`delete-account` Edge Function** (client SDKs can't self-delete). The function verifies the JWT, purges the user's PDFs from storage, then `auth.admin.deleteUser()`. `profiles` + `checklist_completions` follow via `on delete cascade`. |
| Update profile | `updateProfile({fullName, licenseNumber, homeBase})` | `profiles` update (own row) |
| Join a school | `joinFlightSchool(code)` | `rpc('join_flight_school')` |
| Leave a school | `leaveFlightSchool()` | `rpc('leave_flight_school')` |
| Rotate invite code | `rotateInviteCode()` | `rpc('rotate_flight_school_invite_code')` (admin) |
| Set entitlement | `setSubscription({premium, productId, expiresAt})` | `profiles` update (own row) — used by the IAP flow |

### Guest access (unchanged)

`auth_gate.dart` sends guests straight to `HomeScreen`. Only a signed-in
`flight_school_admin` is routed to `FlightSchoolDashboard`. Checklists,
weather and the training game never require an account. The completion
screens and paywall show a "sign in to…" prompt instead of blocking.

### ⚠️ Invite-code join flow — UI not yet built

The RPCs (`join_flight_school`, `leave_flight_school`,
`rotate_flight_school_invite_code`) and the service methods exist and are
covered by RLS/tests-by-inspection, but there is **no screen** yet for a
pilot to enter a code or for an admin to view/rotate theirs. Until that's
added, populate `profiles.flight_school_id` for test pilots via SQL or the
seed script. See §6.

---

## 3. Checklist completion + PDF flow

**Service:** `lib/services/supabase_pdf_service.dart` (`SupabasePdfService`).
Replaces `PdfUploadService` (AWS Lambda `POST /pdf`), now a deprecated no-op
shim.

### Write path (`recordCompletion`)

Called from the 3 pre-boarding checklist screens
(`cessna_152_checklist.dart`, `cessna_172_checklist.dart`,
`piper_pa28_checklist.dart`) right after they build the PDF locally with
`package:pdf` (unchanged) and before `OpenFile.open`. Best-effort: silently
skipped for guests, never blocks opening the local file.

1. `INSERT` a `checklist_completions` row — `user_id = auth.uid()`,
   `flight_school_id` = the cached profile's value (the denormalised
   snapshot), `aircraft_type`, `checklist_name`, `completed_at`.
2. Upload the PDF bytes to `checklist-pdfs` at `{user_id}/{id}.pdf`
   (`contentType: application/pdf`, `upsert: true`).
3. `UPDATE` the row's `pdf_storage_path`. If the upload fails the row is
   kept (a valid "checklist was completed" record, just without a PDF).

### Read paths

| Who | Method | Screen |
|---|---|---|
| Pilot | `listMyCompletions()` — own rows, newest first | `screens/completions/my_completions_screen.dart` — drawer **"My Checklists"** (replaced the fake local "My PDFs") |
| Admin | `listSchoolCompletions({aircraftType, from, to})` — RLS-scoped to their school; embeds `profiles(full_name)` for the pilot name | `screens/completions/school_completions_screen.dart` — dashboard **"Checklist Completions"** action + drawer item, route `/flight-school/completions` |

Opening a PDF: `downloadPdfToTemp()` pulls the private object to a temp file →
`OpenFile.open`. `signedUrl()` is available for share/browser use.

### Not migrated (deliberately, flagged)

- **`PdfService` + `pdf_list_screen.dart`** ("My PDFs" that generated throwaway
  dummy PDFs) — now unreferenced. Safe to delete.
- **`LocalPdfRepository` + `PdfStorageHelper` + `pdf_library_screen.dart`** —
  the flight-school on-device PDF library, fed by the emergency/preflight
  screens. Still local-only. The dashboard now links the Supabase-backed
  "Checklist Completions" as the primary path and labels the old one
  "legacy". Migrating the emergency-drill / tech-log / fuel-uplift /
  passenger-brief / departure-briefing PDFs into `checklist_completions`
  (or a sibling table) is a **follow-up** — those still call the deprecated
  `PdfUploadService` shim (no-op).

---

## 4. Weather (AVWX) flow

**Edge Function `get-weather`** (`supabase/functions/get-weather/index.ts`).
`verify_jwt = false` — weather works for guests; the function is the trust
boundary.

- Request: `POST { endpoint: metar|taf|station|pirep|airsigmet, icao?, coords?, options? }`
- The function validates inputs, calls `https://avwx.rest/api/...` with
  `Authorization: Token <AVWX_TOKEN>` (a **secret**, never in the client),
  and returns AVWX's body + status **unchanged**.
- `lib/utils/weather_service.dart`: the hardcoded token
  (`dev-PdSRG3eHIS_…`) and all `package:http` calls are **gone**. Every method
  now goes through a private `_invoke()` that calls
  `Supabase.instance.client.functions.invoke('get-weather', body: {...})`.
  All response **parsing** (`parseMETARBody`, TAF periods, hazards, station
  runways) is byte-for-byte the same.

Set the secret (you do this with the real token):

```bash
supabase secrets set AVWX_TOKEN=<the real AVWX token>
supabase functions deploy get-weather
```

---

## 5. StoreKit IAP flow

**Service:** `lib/services/iap_service.dart` (`IapService`).
**Paywall:** `lib/screens/paywall_screen.dart` (rewritten).

- Packages: `in_app_purchase`, `in_app_purchase_storekit`. iOS deployment
  target raised **12.0 → 15.0** (`project.pbxproj` ×3, `AppFrameworkInfo.plist`,
  new `ios/Podfile`) — required for StoreKit 2.
- On iOS, `InAppPurchaseStoreKitPlatform.enableStoreKit2()` so
  `verificationData.serverVerificationData` is the **signed JWS transaction**.
- **Product IDs are placeholders**, clearly marked, in `lib/config/config.dart`:
  `kMonthlySubscriptionId = 'TODO_REPLACE_clearedtogo_premium_monthly'`,
  `kYearlySubscriptionId = 'TODO_REPLACE_clearedtogo_premium_yearly'`.
  Querying them returns "not found" until the real auto-renewable products
  exist in App Store Connect.
- Purchase: `buyNonConsumable` → listen on `purchaseStream` →
  on `purchased`/`restored`, `_verify()` the JWS payload (right `productId`,
  no `revocationDate`, read `expiresDate`) → `setSubscription(premium: true,
  productId, expiresAt)` on the Supabase profile → `completePurchase`.
- **Restore Purchases** implemented (`restorePurchases()`), required by Apple.
- Paywall is a **custom** screen (no `SubscriptionStoreView`): shows each
  plan's title, length ("1 month" / "1 year"), and price (from StoreKit
  `ProductDetails`, falling back to `kMonthlyPrice`/`kYearlyPrice`), the
  auto-renew disclosure, and **functional links** — Privacy Policy (in-app
  `PrivacyPolicyScreen`) and Terms of Use / EULA (`kTermsOfUseUrl`, currently
  Apple's standard EULA — swap for your own hosted EULA if preferred).
- The old *"Subscriptions aren't available yet"* interim copy is **removed**.
- `kDisablePaywallForDev = true` still short-circuits to grant premium with no
  store round-trip, for local testing.

### ⚠️ Client-side entitlement only — explicit limitation

`profiles.subscription_status` is written **by the app** after a locally
verified purchase. This does **not** track:

- renewals (status won't flip back to `free` when a sub lapses)
- expiry / grace periods / billing retry
- refunds and Apple-initiated revocations
- cancellations

The JWS signature is **not** cryptographically verified on-device (needs
Apple's root certs / a server).

**Production follow-up (not built):** an Edge Function subscribed to **App
Store Server Notifications V2** that updates `profiles.subscription_status` /
`subscription_expires_at` server-side, plus a periodic reconciliation using
the App Store Server API. This was deliberately deferred per the brief — ship
the simple version, revisit.

---

## 6. Environment variables & secrets

| Name | Where it lives | Used by | Secret? |
|---|---|---|---|
| `SUPABASE_URL` | root `.env` (gitignored; `.env.example` committed) + `scripts/.env` + Edge Function env (auto on hosted) | Flutter `main()` via `flutter_dotenv` → `Env.supabaseUrl`; seed script; `delete-account` | No (project ref) |
| `SUPABASE_ANON_KEY` | root `.env` | Flutter `Supabase.initialize` | No (publishable, but kept out of git) |
| `SUPABASE_SERVICE_ROLE_KEY` | `scripts/.env` **only**; Edge Function secret (`SUPABASE_SERVICE_ROLE_KEY` auto-injected on hosted platform) | `scripts/seed_dev_user.mjs`; `delete-account` Edge Function | **YES — bypasses RLS. Never in Flutter, never committed.** |
| `AVWX_TOKEN` | Edge Function secret only (`supabase secrets set AVWX_TOKEN=…`) | `get-weather` Edge Function | **YES — paid API key. Never in the client.** |
| `SEED_PILOT_EMAIL` / `SEED_ADMIN_EMAIL` / `SEED_SCHOOL_NAME` | optional, `scripts/.env` | seed script overrides | No |

`.gitignore` additions: `.env`, `.env.*` (except `.env.example`),
`scripts/.env`, `scripts/node_modules/`, `supabase/.branches/`,
`supabase/.temp/`, `supabase/.env`.

The `.env` bundled into the app is listed under `flutter: assets:` in
`pubspec.yaml` so `flutter_dotenv` can read it at runtime. A placeholder
`.env` is committed-ignored but present so a fresh checkout builds; fill it
with real values.

---

## 7. What AWS / Cognito code was removed

**Deleted files**

| File | Was |
|---|---|
| `lib/services/auth_service.dart` | Cognito `AuthService` + `Tom`/`David` bypass |
| `lib/services/auth_service_manager.dart` | local-store singleton |
| `lib/repositories/auth_repository.dart` | abstract repo |
| `lib/repositories/local_auth_repository.dart` | SharedPreferences user store + seeded `school@demo.com` |
| `lib/amplifyconfiguration.dart` | hardcoded Cognito pool/client/region JSON |
| `lib/screens/auth/email_verification_screen.dart` | Cognito confirm-signup screen |

**Rewritten away from AWS**

- `lib/main.dart` — `Amplify.configure` → `dotenv.load` + `Supabase.initialize`
- `lib/services/pdf_upload_service.dart` — AWS Lambda POST → deprecated no-op shim
- `lib/utils/weather_service.dart` — direct AVWX + hardcoded token → `get-weather` Edge Function
- `lib/models/user_role.dart` — old `User` class removed; now re-exports `Profile`/`UserRole`
- `lib/screens/auth/{auth_gate,login_screen,signup_screen}.dart` — two-system logic removed
- `lib/screens/privacy_policy.dart` — "AWS Cognito" wording → Supabase
- `pubspec.yaml` — `amplify_flutter`, `amplify_auth_cognito` removed

**Dependency swap:** `flutter pub get` confirms `amplify_*` / `aws_*`
packages are gone from `pubspec.lock`; `supabase_flutter`, `gotrue`,
`postgrest`, `realtime_client`, `flutter_dotenv`, `in_app_purchase`,
`in_app_purchase_storekit` are in.

**Confirmation — nothing in the client still references AWS/Cognito/AVWX
secrets:** `grep -rniE "amplify|cognito|execute-api|dev-PdSRG3" lib/` returns
only explanatory comments in `supabase_auth_service.dart`, `profile.dart`,
`user_role.dart` and the `pdf_upload_service.dart` shim that describe *what
was replaced*. No live code, no endpoints, no tokens.

**Not touched (backend, outside this repo):** the AWS Cognito user pool
`eu-west-2_KQNfYWFT4`, the API Gateway/Lambda behind
`4cx5f0qdab.execute-api.eu-west-2.amazonaws.com`, and whatever storage that
Lambda used. Decommission those in AWS once the Supabase cutover is verified.

---

## 8. Follow-ups / not finished

1. **Invite-code UI** — pilot "enter school code" + admin "view/rotate code"
   screens. Backend + service methods are done.
2. **Server-side subscription tracking** — App Store Server Notifications V2
   Edge Function (see §5).
3. **JWS signature verification** — currently payload-only on-device.
4. **Emergency / preflight-systems PDFs** — still on the `PdfUploadService`
   no-op shim; migrate into `checklist_completions` or a sibling table.
5. **Delete dead code** — `PdfService`, `pdf_list_screen.dart`, and
   (once #4 lands) `LocalPdfRepository` / `PdfStorageHelper` /
   `pdf_library_screen.dart`.
6. **Email confirmation** — disabled. To enable: flip
   `enable_confirmations = true` in `config.toml`, configure SMTP, and
   re-introduce a verification screen in the Flutter signup path.
7. **Real product IDs, `kPrivacyPolicyUrl`, EULA URL** — placeholders in
   `lib/config/config.dart`.
8. **End-to-end verification** — none of this has run against a live Supabase
   project yet (no CLI/node on the dev machine used). `flutter analyze` is
   clean.
