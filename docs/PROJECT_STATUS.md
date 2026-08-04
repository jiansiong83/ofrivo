# Project Status

## Current stable version

Step 11 Security and Testing (local security contract validation; Supabase integration scenarios are ready for an isolated runtime).

## Current objective

Prepare the Step 12 closed-beta release package while preserving account privacy, transactional invariants, actionable error states, and runtime-only secrets.

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
- Auth unit tests added and passing with the prepared Flutter SDK.
- Step 4 customer job form, photo picker adapter, draft/preview/publish flow, My Jobs, Job Detail, cancellation, and fake/Supabase repositories added.
- Job draft validation and fake repository lifecycle tests added and passing.
- Step 5 provider application form, category/area selection, private evidence/work-photo upload adapter, status UI, fake/Supabase repository, and server submission RPC added.
- Provider application validation and fake lifecycle tests added and passing.
- Flutter stable SDK 3.44.8 / Dart 3.12.2 prepared at `F:\Dev\FlutterSDK`; Android licenses accepted and user PATH updated.
- Android platform host generated with `flutter create --platforms=android .`; Kotlin incremental compilation disabled for the Windows cross-drive cache layout.
- Step 6 provider feed/bid models, repository/controller, safe feed view migration, filters, job detail, bid submit/edit/withdraw, and My Bids screens added.
- Step 6 fake lifecycle tests and static contract validation added.
- Step 7 customer Received Bids, Provider Profile, fake/Supabase bid repositories, and transactional acceptance controller added.
- Customer acceptance updates the selected bid to accepted, rejects other pending bids, updates the job to assigned, and refreshes the customer Job Detail state.
- Provider Assigned Jobs now load only accepted-provider jobs and reveal full address/contact fields through the authorized assigned-job query.
- Notification repository/controller and read-state UI added for fake data and the Supabase `notifications` table.
- Step 7 fake acceptance/concurrency guard tests and static RPC/mobile contract validation added.
- Step 8 lifecycle repository/controller added for start, complete, and assigned-job cancellation through the existing transaction RPCs.
- Review and Report flows added with rating/comment validation, reason selection, participant-aware Supabase inserts, and fake-data adapters.
- Job Event Log timeline added to customer and provider job details.
- Step 8 lifecycle tests and static RPC/mobile contract validation added.
- Step 9 Admin Web console added with local login preview and operational Dashboard.
- Provider verification supports approve, reject, and suspend actions with private-evidence signed-preview guidance.
- Users supports suspend/restore; Jobs and Bids expose admin-scoped marketplace monitoring; Reports supports reviewing, resolving, and dismissing.
- Categories, Areas, System Settings, and Audit Log views added; every moderation mutation appends an attributable local audit event.
- Step 9 static Admin Web contract validator added.
- Step 10 device-token repository/source/controller added with fake mode and Supabase `register_device_token`/`unregister_device_token` RPC adapters.
- Notification event types expanded for new matching jobs, job expiry, and provider verification results; the mobile shell now shows an unread badge and supports mark-all-read.
- Step 10 SQL migration adds new-job, new-bid, verification-result, and scheduled job-expiry notification fan-out with user-scoped device-token validation.
- Step 10 seed fixture, notification tests, and static push contract validator added.
- Step 11 manual SQL scenarios added for RLS, private Storage, multiple accounts, concurrent bid acceptance, and invalid state errors.
- Image validation now checks extension, file signature, file size, count, duplicate paths, missing files, and is wired into customer/provider pickers.
- Error states expose a working retry action; an offline state component and global crash diagnostic capture are included.
- Multi-account, image, crash, error/offline widget, and Step 11 static security contract tests added.
- Step 12 release signing guard, keystore example, closed-beta runbook, bug report template, and static readiness validator added.

## Not completed yet

- No Supabase Cloud project connection or production FCM credentials/native delivery bridge; push tokens can be supplied at runtime and the notification rows remain the durable outbox.
- Admin Web is intentionally a local fake-data preview until server-side Supabase Auth claims, RLS-backed queries, signed URLs, and audit writes are configured.
- Supabase RLS/Storage/multi-account/concurrency scenarios are documented but not executed because Docker, PostgreSQL, and Supabase CLI are unavailable in this workspace.
- Closed Beta remains externally gated by a permanent Android application ID, production upload keystore, Google Play Console access, isolated beta project, and real tester accounts.

## Known issues / environment

- Android SDK is present and Android licenses are accepted; `adb` remains available by absolute path but is not currently on PATH in this shell.
- Admin commands may require `npm.cmd` on this PowerShell host.

## Database migration

`supabase/migrations/20260804000100_step2_foundation.sql` — local source added; not applied to a cloud project.

## Test/build result

- Admin lint: PASS.
- Admin production build: PASS (static `/` output).
- Admin Step 2 regression lint/build: PASS.
- Flutter analyze: PASS — `No issues found!` (Flutter 3.44.8).
- Flutter test: PASS — 28 tests passed.
- Android debug build: PASS — `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Dependency install: Admin dependencies installed; ESLint/PostCSS were updated to patched releases and `npm audit` now reports 0 vulnerabilities.
- Step 2 SQL static contract validation: PASS (`node supabase/tests/validate_step2.mjs`).
- Supabase CLI local lint: BLOCKED — no local PostgreSQL/Docker runtime is available (`LegacyDbConnectError`).
- Auth, customer job, provider application, and onboarding widget tests: PASS — 10 tests passed.
- Provider feed filters, bid edit/withdraw, and bid validation tests: PASS — 5 additional tests.
- Step 6 SQL/mobile static contract validation: PASS (`node supabase/tests/validate_step6.mjs`).
- Step 7 RPC/mobile static contract validation: PASS (`node supabase/tests/validate_step7.mjs`).
- Step 8 lifecycle/mobile static contract validation: PASS (`node supabase/tests/validate_step8.mjs`).
- Step 9 Admin Web static contract validation: PASS (`node supabase/tests/validate_step9.mjs`).
- Step 9 Admin lint: PASS (`npm.cmd run lint`).
- Step 9 Admin production build: PASS (`npm.cmd run build`, static `/` output).
- Step 10 push static contract validation: PASS (`node supabase/tests/validate_step10.mjs`).
- Step 10 Flutter analyze: PASS (`No issues found!`).
- Step 10 Flutter test: PASS (23 tests passed).
- Step 10 Android debug build: PASS (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- Step 11 security/testing static contract validation: PASS (`node supabase/tests/validate_step11.mjs`).
- Step 11 Flutter analyze: PASS (`No issues found!`).
- Step 11 Flutter test: PASS (28 tests passed).
- Step 11 Android debug build: PASS (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- Supabase CLI/Docker integration suite: BLOCKED; run `supabase/tests/step11_security_and_testing.sql` when an isolated runtime is available.
- Step 12 closed-beta readiness validation: PASS (`node scripts/validate_closed_beta.mjs`).
- Step 12 local debug-signed AAB smoke: PASS (`apps/mobile/build/app/outputs/bundle/release/app-release.aab`); this artifact is not Play-uploadable.
- Step 12 signed AAB/Play internal and closed-test validation: BLOCKED until release secrets, Play access, and beta runtime are supplied.
- Step 3/4/5 static source review: PASS; no runtime Supabase values or service-role key committed.

## Commit ID / rollback point

Step 10 commit: `883dcf0` (`feat: add push-ready notification pipeline`). Step 11 commit: `12d3916` (`feat: add security and resilience checks`). Step 12 release-prep commit: `716799c` (`feat: prepare closed beta release signing`). Rollback point is the Step 11 docs commit `abc69ae`.

## Next step

Next: Step 12 Closed Beta.
