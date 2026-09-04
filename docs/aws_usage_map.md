# AWS usage map

Read-and-document snapshot of every place this app talks to AWS, as of this
pass. No AWS config or credentials were changed while producing this file.

## 1. Cognito (authentication)

- **User pool**: `eu-west-2_KQNfYWFT4`
- **App client ID**: `6fd41jdeqfrlhue3fi1gnmctf7`
- **Region**: `eu-west-2`
- Config source: [`lib/amplifyconfiguration.dart`](../lib/amplifyconfiguration.dart) — a single hardcoded JSON blob passed to `Amplify.configure()`. No `amplifyconfiguration.json` asset, no per-environment config.
- **Auth flow**: standard Amplify Cognito username/password (SRP), with email as the username. No MFA, no social/federated sign-in, no Hosted UI.
- Plugin wiring: [`lib/main.dart`](../lib/main.dart) `_configureAmplify()` — adds `AmplifyAuthCognito()` and calls `Amplify.configure(amplifyconfig)` inside a try/catch with a 5s timeout; the app deliberately continues even if Amplify fails to configure.

### Call sites (all in `AuthService`, [`lib/services/auth_service.dart`](../lib/services/auth_service.dart))

| Action | Function | Amplify call | Called from |
|---|---|---|---|
| Sign up | `signUpWithCognito()` | `Amplify.Auth.signUp()` | [`signup_screen.dart`](../lib/screens/auth/signup_screen.dart) `_handleSignup()` |
| Confirm email | — | `Amplify.Auth.confirmSignUp()` / `resendSignUpCode()` | [`email_verification_screen.dart`](../lib/screens/auth/email_verification_screen.dart) |
| Sign in | `loginWithCognito()` | `Amplify.Auth.signIn()` | [`login_screen.dart`](../lib/screens/auth/login_screen.dart) `_handleLogin()` |
| Read auth state | `isLoggedIn()`, `_loadCognitoUser()` | `Amplify.Auth.fetchAuthSession()`, `getCurrentUser()`, `fetchUserAttributes()` | [`auth_gate.dart`](../lib/screens/auth/auth_gate.dart), drawer premium/sign-in checks, `PdfUploadService` |
| Update profile | `updateProfile()` | `Amplify.Auth.updateUserAttribute()` | [`account_details_screen.dart`](../lib/screens/auth/account_details_screen.dart) |
| Sign out | `logout()` | `Amplify.Auth.signOut()` | [`app_drawer.dart`](../lib/widget/app_drawer.dart) Logout tile |
| **Delete account** | `deleteAccount()` *(added this pass)* | `Amplify.Auth.deleteUser()` | `account_details_screen.dart` `_deleteAccount()` |

### Two parallel, independent auth systems (worth knowing before any migration)

The app actually has **two separate user stores that don't share data**:

1. **`AuthService`** (above) — real Cognito users, plus one hardcoded bypass account (`Tom` / `David`, see `auth_service.dart:221`) that skips Cognito entirely and is treated as a local admin.
2. **`AuthServiceManager` → `LocalAuthRepository`** ([`lib/repositories/local_auth_repository.dart`](../lib/repositories/local_auth_repository.dart)) — a second, fully local (SharedPreferences-only) user store used for flight-school admin/demo accounts (seeded demo login `school@demo.com` / `Demo123!`). This path never touches AWS at all.

`AuthGate` checks `AuthServiceManager` first, then falls back to `AuthService`/Cognito. Also note `AuthService` is **not a singleton** — every screen that does `AuthService()` gets its own instance and must call `.init()` itself before `.currentUser` is populated; a couple of screens (e.g. `paywall_screen.dart`) never call `.init()`, so `.currentUser` reads as `null` there even when signed in. Flag this if you see "signed in" state disagreeing between screens.

## 2. PDF export endpoint (API Gateway + Lambda)

- **Base URL**: `https://4cx5f0qdab.execute-api.eu-west-2.amazonaws.com`
- **Route**: `POST /pdf`
- Client code: [`lib/services/pdf_upload_service.dart`](../lib/services/pdf_upload_service.dart) (`PdfUploadService.uploadPdf()`)

**Request**: plain `http.post`, no Amplify API/Storage category involved — just `package:http`.
- Headers: `Content-Type: application/json`, `Authorization: <raw Cognito ID token>` (the JWT is sent as-is, **not** prefixed with `Bearer `).
- Body (JSON): `{ fileBase64, title, aircraftId, type }` — the PDF is base64-encoded client-side and sent inline in the request body (no pre-signed S3 upload URL flow).
- Requires an active Cognito session; throws if `idToken` is empty.

**Response handling**: the client only checks the HTTP status code (200/201 = success) and discards the response body. It does not receive or store a file URL, ID, or any pointer back to where the Lambda persisted the PDF.

**Where the file actually ends up**: not visible from the client. There is no S3 SDK, bucket name, or storage reference anywhere in this Flutter codebase — whatever the Lambda behind this API Gateway route does with the PDF (S3 object, DynamoDB blob, discarded, etc.) is opaque from here and would need to be checked in the backend/Lambda source, which is outside this repo.

**Callers** (all follow the same pattern: generate PDF locally with `package:pdf` → save to device → best-effort background upload, failures are swallowed and just `debugPrint`ed, never blocking the user):
- `cessna_152_checklist.dart`, `cessna_172_checklist.dart`, `piper_pa28_checklist.dart`
- `cessna_152_emergency_screen.dart`, `cessna_172_emergency_screen.dart`, `piper_pa28_emergency_screen.dart`
- `preflight_systems/pave_assessment_screen.dart`, `tech_log_screen.dart`, `fuel_uplift_screen.dart`, `passenger_brief_screen.dart`, `departure_briefing_screen_new.dart`

**No delete/list/download route exists client-side** — only `POST /pdf`. This matters for account deletion: there is currently no way for the app (or a backend admin) to purge a user's previously-uploaded PDFs via this API. See the account-deletion note in the main summary.

## 3. Storage (S3 or equivalent)

**None found directly in this codebase.** No `amplify_storage_s3` dependency, no S3 bucket name, no pre-signed URL handling anywhere in `lib/`. Two local-only storage paths exist that look like they're *meant* to back onto cloud storage eventually but currently don't:

- `PdfService` ([`lib/services/pdf_service.dart`](../lib/services/pdf_service.dart)) — the "My PDFs" list (`pdf_list_screen.dart`). Purely local: metadata in `SharedPreferences`, PDF bytes are **not persisted at all** (the "Add PDF" button generates a throwaway dummy PDF just to demonstrate the list UI). Extensive inline comments sketch a future `S3`/`api/pdfs` design that was never implemented.
- `LocalPdfRepository` ([`lib/repositories/local_pdf_repository.dart`](../lib/repositories/local_pdf_repository.dart)) — backs the flight-school PDF library / tech log flows. Saves real PDF files to the device's app-documents directory and metadata to `SharedPreferences`. Its `uploadToCloud()` method is a stub that always returns `null` — cloud upload was never implemented for this path either (it's separate from, and does not call, `PdfUploadService`).

So today there are **three unconnected PDF-handling code paths** (`PdfUploadService` → real backend; `PdfService` → fake local-only list; `LocalPdfRepository` → real local files, fake cloud stub). Worth consolidating regardless of any Supabase decision.

## 4. Hardcoded endpoints, regions, IDs and tokens found in source

| Value | File:line | Notes |
|---|---|---|
| Cognito Pool ID `eu-west-2_KQNfYWFT4` | [`lib/amplifyconfiguration.dart:9`](../lib/amplifyconfiguration.dart#L9) | |
| Cognito App Client ID `6fd41jdeqfrlhue3fi1gnmctf7` | [`lib/amplifyconfiguration.dart:10`](../lib/amplifyconfiguration.dart#L10) | |
| Region `eu-west-2` | [`lib/amplifyconfiguration.dart:11`](../lib/amplifyconfiguration.dart#L11) | matches expected region |
| API Gateway base URL `https://4cx5f0qdab.execute-api.eu-west-2.amazonaws.com` | [`lib/services/pdf_upload_service.dart:10`](../lib/services/pdf_upload_service.dart#L10) | region `eu-west-2` embedded in hostname |
| **AVWX API token** `dev-PdSRG3eHIS_NXKZD5jHtvACnHsmN_Y1W4aLnhNY` | [`lib/utils/weather_service.dart:6`](../lib/utils/weather_service.dart#L6) | ⚠️ **flagged as requested** — not an AWS credential, but a live third-party API token shipped in client source (readable by anyone who decompiles/inspects the app bundle). The `dev-` prefix suggests this may itself be a development-tier key. Should be moved server-side (proxied through your own backend) or at minimum rotated periodically since it's public once shipped. |
| Hardcoded admin bypass credentials `Tom` / `David` | [`lib/services/auth_service.dart:221`](../lib/services/auth_service.dart#L221) | not AWS, but a hardcoded credential in shipped source — flagging alongside the above since it's the same class of issue |
| Demo admin credentials `school@demo.com` / `Demo123!` | [`lib/repositories/local_auth_repository.dart:18-26`](../lib/repositories/local_auth_repository.dart#L18) | local-only seeded account, not AWS |

No other AWS access keys, secret keys, or session tokens were found anywhere in `lib/`. The app never uses raw AWS SigV4 credentials directly — all AWS access goes through either Amplify (Cognito) or a plain authenticated HTTPS call to API Gateway.

## 5. Surface-area summary

| AWS feature | Load-bearing? | What it does today | Supabase equivalent |
|---|---|---|---|
| Cognito User Pool | **Load-bearing**, but only for the subset of users who choose to sign in (sign-in is optional post-fix; see section A of the main summary) | Email/password auth, profile attribute (`name`) storage | Supabase Auth (email/password) — direct swap; would also let you delete the two-auth-system split (item 1 above) by moving the local flight-school/demo accounts into the same table as everyone else |
| API Gateway + Lambda `/pdf` | **Load-bearing** for the "auto-backup my PDF" feature, but non-blocking — every caller already treats it as best-effort and works fully offline if it fails | Accepts a base64 PDF + metadata over HTTPS, presumably persists it server-side (opaque to this repo) | Supabase Edge Function (same HTTPS contract) writing to Supabase Storage, or a direct authenticated client upload to Supabase Storage + a Postgres row for metadata — the latter would also finally give you list/delete, which don't exist today |
| S3 / object storage | **Incidental / not actually used** — referenced only in comments and stub methods, nothing live | N/A | Supabase Storage bucket, once you actually wire up cloud PDF storage |
| DynamoDB or any other AWS data store | **Not used** — no evidence anywhere in this repo. All "backend" state (profile fields, PDF metadata, PAVE history, premium flag) currently lives in on-device `SharedPreferences` | N/A today | Supabase Postgres — this is the biggest gap. None of profile data, premium/subscription status, or checklist/PAVE history currently persist anywhere off-device or sync across installs; that's all local-only right now regardless of AWS vs. Supabase |

**Bottom line**: the only AWS services actually in play are Cognito (auth) and one API Gateway/Lambda route (PDF ingest, whose storage backend is invisible from the client). Everything else that looks "cloud-ready" in the code (S3 upload stubs, `/api/pdfs` REST comments, cloud sync mentions in the paywall copy) is unimplemented scaffolding. A Supabase migration is mostly a Cognito→Supabase-Auth swap plus actually building the Postgres-backed persistence that doesn't exist yet — it wouldn't be replacing a lot of existing AWS surface area.
