# Project Status

## Current stable version

Step 3 authentication/profile foundation (runtime connection optional; Flutter validation remains environment-blocked).

## Current objective

Add the mobile Email + Password Auth/Profile adapter on top of the local Supabase foundation without committing hosted credentials.

## Completed

- Master plan reviewed in full.
- Empty workspace confirmed and Git repository initialized.
- Monorepo folders, README, ignore rules, assets placeholders, and Supabase placeholders added.
- Flutter fake-data shell added with Riverpod, go_router, Material 3, feature folders, routes, fake models/data, and reusable widgets.
- Next.js 16 + TypeScript + Tailwind Admin dashboard placeholder added.
- Product, screen map, UI, data, security, test, changelog, and release documents added.
- Admin `npm.cmd run lint` passed.
- Admin `npm.cmd run build` passed with Next 16.3.0.
- Step 2 migration added for all planned entities, constraints, indexes, Storage buckets, RLS policies, safe views, and RPCs.
- Step 2 seed added with local auth fixtures, categories, areas, providers, jobs, bids, and notifications.
- Step 3 mobile Auth repository/controller added with runtime `--dart-define` configuration and local demo fallback.
- Profile restore/upsert, sign-out, password reset, suspended-account guard, and Provider Mode guard added.
- Auth unit tests added (not runnable until Flutter SDK is available).

## Not completed yet

- No Supabase Cloud project connection or FCM connection; app-side auth connects only when runtime defines are supplied.
- Flutter `analyze`, `test`, and Android debug build could not start because Flutter/Dart are not installed or on PATH.

## Known issues / environment

- Flutter and Dart are not currently available on PATH, so Flutter validation may remain blocked unless an SDK is discovered or installed.
- Android SDK is present; `adb` is not currently on PATH.
- Admin commands may require `npm.cmd` on this PowerShell host.

## Database migration

`supabase/migrations/20260804000100_step2_foundation.sql` — local source added; not applied to a cloud project.

## Test/build result

- Admin lint: PASS.
- Admin production build: PASS (static `/` output).
- Admin Step 2 regression lint/build: PASS.
- Flutter analyze: BLOCKED — `flutter` command not recognized.
- Flutter test: BLOCKED — `flutter` command not recognized.
- Android debug build: BLOCKED — `flutter` command not recognized.
- Dependency install: Admin dependencies installed; ESLint/PostCSS were updated to patched releases and `npm audit` now reports 0 vulnerabilities.
- Step 2 SQL static contract validation: PASS (`node supabase/tests/validate_step2.mjs`).
- Supabase CLI local lint: BLOCKED — no local PostgreSQL/Docker runtime is available (`LegacyDbConnectError`).
- Auth unit/widget tests: BLOCKED — Flutter SDK is not available on PATH.
- Step 3 static source review: PASS; no runtime Supabase values or service-role key committed.

## Commit ID / rollback point

Step 2 commit and rollback point are to be recorded after verification. Rollback point is the Step 1 commit `77ac8d7`.

## Next step

After this round is accepted: Step 4 Customer Job Creation.
