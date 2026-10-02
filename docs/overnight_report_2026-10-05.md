# Dev user reset — 5 Oct 2026

Branch: `flight-school-accountability`. Bounded session: reset `auth.users` down to exactly 3 accounts. Ground-systems UI polish and docs/migration cleanup were intentionally out of scope and not touched.

## Inventory (Phase 1)

`auth.users` had exactly 8 rows, matching the known list with no surprises:
`thomasmalins@proton.me`, `demo.pilot2@clearedtogo.test` (Jamie Chen), `demo.pilot1@clearedtogo.test` (Alex Morgan), `weareclearedtogo@gmail.com`, `thomas.malins@adaptive-mdc.com`, `todo_replace_devon_somerset_admin@clearedtogo.test` (Devon & Somerset placeholder admin), `dev.admin@clearedtogo.test`, `dev.pilot@clearedtogo.test`.

## Final 3 accounts (Phase 2)

Kept, untouched apart from a password reset:
- `weareclearedtogo@gmail.com` — business_admin, "ClearedToGo Team"
- `thomasmalins@proton.me` — flight_school_admin, Demo Flight School
- `demo.pilot1@clearedtogo.test` (Alex Morgan) — pilot, Demo Flight School — her 3 `checklist_completions` rows were left untouched throughout

## Deletions — via the real `delete-account` Edge Function (Phase 2)

The function is self-service only (it resolves the caller's own uid from their JWT, not an arbitrary target), so each deletion was done as a real exercise of that path: set a one-off temporary password via the Admin API, signed in as that account to get a session token, then called `delete-account` with that token — the same flow the app itself uses, not a direct DB delete.

All 5 returned `200 {"ok":true,"deleted":"<uid>"}`:
- `demo.pilot2@clearedtogo.test` (Jamie Chen)
- `dev.admin@clearedtogo.test`
- `dev.pilot@clearedtogo.test`
- `thomas.malins@adaptive-mdc.com`
- `todo_replace_devon_somerset_admin@clearedtogo.test` (Devon & Somerset placeholder admin)

Verified clean afterward: `auth.users` down to exactly 3 rows; zero orphaned `profiles` or `checklist_completions` rows for any of the 5 deleted ids (cascade worked); Alex Morgan's 3 completions confirmed still present and untouched.

## Passwords (Phase 3)

Real, memorable passwords set for all 3 surviving accounts via the Admin API, documented in [docs/DEV_CREDENTIALS.md](DEV_CREDENTIALS.md). That file is internal-only dev data for a private repo — to be deleted before any public launch, per its own header.

## Scope verification (Phase 4)

Signed in as all 3 and confirmed RLS scoping:
- **business_admin** (`weareclearedtogo@gmail.com`): sees all remaining flight schools (Demo Flight School, Independent Pilots, plus Dev Flight School and Devon & Somerset Flying School — those two school records still exist even though their admin accounts were just deleted) and all 3 of Alex Morgan's completions (the only completions left in the system).
- **flight_school_admin** (`thomasmalins@proton.me`): sees exactly 2 profiles (itself + Alex Morgan), exactly 1 school (Demo Flight School), and exactly Alex Morgan's 3 completions.
- **pilot** (`demo.pilot1@clearedtogo.test`): sees exactly her own profile, her own school, and her own 3 completions.

All three scopes are correct — no bleed-through between schools or roles.

## Out of scope

Ground-systems UI polish and docs/migration cleanup were intentionally not touched this session.
