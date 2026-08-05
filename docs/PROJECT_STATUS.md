# Project Status

## Current stable version

Version 1.1 Phone OTP, three-language foundation, Provider Portfolio, No-show marker, Job auto-expire, and richer review dimensions (local Docker validation complete; real SMS/FCM delivery remains configuration-gated).

## Current objective

Continue Version 1.1 hardening while preserving account privacy, transactional invariants, actionable error states, and runtime-only secrets. Core entry/auth/navigation copy now supports English, Bahasa Melayu, and Chinese; approved-provider portfolio photos are separated from private evidence; no-show reports are participant-derived and duplicate-safe; open jobs now have a service-only expiry worker with event/notification outbox writes; reviews now capture punctuality, quality, and communication dimensions; deep business-page translation remains tracked. Google Play distribution is intentionally deferred for now.

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
- Version 1.1 Phone OTP added with E.164 normalization, Supabase SMS request/verify, phone-only profile fallback, local demo code, route/UI states, and repository/controller tests.
- Version 1.1 three-language foundation added with persisted `en`/`ms`/`zh` selection, Material locale propagation, language picker, translated onboarding/auth copy, and translated shell navigation.
- Version 1.1 Provider Portfolio added with a dedicated public Storage bucket, approved-active public view, owner-scoped uploads, URL mapping, fake fixtures, gallery fallbacks, and profile surfaces.
- Version 1.1 No-show marker added with `mark_no_show`, participant-only authorization, duplicate protection, private event metadata, typed notifications, fake parity, confirmation UI, and local RPC runner.
- Version 1.1 Job auto-expire added with publish-time seven-day defaults, bounded service-only worker, row locking, pending-bid expiration, event/notification outbox writes, fake parity, and local RPC runner.
- Version 1.1 richer review dimensions added with required punctuality, quality, and communication scores, database bounds, fake/Supabase persistence, detailed score controls, and local integration runner.
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
- Local Supabase integration runner added; migration ordering, Storage UUID/text comparison, RLS recursion, service-role grants, and Auth fixture compatibility were verified and corrected against Docker Postgres.
- Step 12 release signing guard, keystore example, closed-beta runbook, bug report template, and static readiness validator added.

## Not completed yet

- No Supabase Cloud project connection or production FCM credentials/native delivery bridge; push tokens can be supplied at runtime and the notification rows remain the durable outbox.
- Admin Web is intentionally a local fake-data preview until server-side Supabase Auth claims, RLS-backed queries, signed URLs, and audit writes are configured.
- Hosted Supabase RLS/Storage/multi-account/concurrency scenarios remain pending; the equivalent isolated local Docker run passes, but no cloud project is connected.
- Closed Beta remains externally gated by a permanent Android application ID, production upload keystore, Google Play Console access, isolated beta project, and real tester accounts.
- Real Phone OTP delivery remains externally gated by Supabase SMS provider/sender configuration; the local demo path is deterministic and offline.
- Deep business-page copy still needs migration and review in all three languages; the current switch is intentionally scoped to entry, auth, and shell surfaces.
- Provider Portfolio hosted rollout still needs the migration applied to the target Supabase project and real public image review; local Docker reset/lint passed.
- No-show hosted rollout still needs the migration applied to the target Supabase project and real participant/device review; local RPC runner passes.
- Job auto-expire hosted rollout still needs the migration applied to the target Supabase project and a managed scheduler/service-role runtime; local expiry runner passes.
- Richer review dimensions hosted rollout still needs the migration applied to the target Supabase project and real participant/device review; local runner passes.

## Known issues / environment

- Android SDK and Docker Desktop are available; `adb` is on PATH but no Android device is currently connected.
- Admin commands may require `npm.cmd` on this PowerShell host.

## Database migration

Step 2 through Version 1.1 review-dimension migrations are applied and seeded in the isolated local Docker project on ports `54420`–`54427`; the Version 1.1 migrations are `supabase/migrations/20260805000200_version11_provider_portfolio.sql`, `supabase/migrations/20260805000300_version11_no_show.sql`, `supabase/migrations/20260805000400_version11_job_expiry.sql`, and `supabase/migrations/20260805000500_version11_review_dimensions.sql`. They are not applied to a cloud project.

## Test/build result

- Admin lint: PASS.
- Admin production build: PASS (static `/` output).
- Admin Step 2 regression lint/build: PASS.
- Flutter analyze: PASS — `No issues found!` (Flutter 3.44.8).
- Flutter test: PASS — 28 tests passed.
- Android debug build: PASS — `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Dependency install: Admin dependencies installed; ESLint/PostCSS were updated to patched releases and `npm audit` now reports 0 vulnerabilities.
- Step 2 SQL static contract validation: PASS (`node supabase/tests/validate_step2.mjs`).
- Supabase local database reset: PASS (`npx.cmd --yes supabase@2.109.1 db reset --yes`).
- Supabase local database lint: PASS (`npx.cmd --yes supabase@2.109.1 db lint`; no schema errors).
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
- Step 11 security/testing static contract validation: PASS (`node supabase/tests/validate_step11.mjs`, 22 checks).
- Step 11 Flutter analyze: PASS (`No issues found!`).
- Step 11 Flutter test: PASS (28 tests passed).
- Step 11 Android debug build: PASS (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- Step 11 local Docker integration suite: PASS (`node supabase/tests/run_step11_local.mjs`, 19 checks).
- Hosted Supabase permission/concurrency suite: PENDING until a cloud project is connected.
- Step 12 closed-beta readiness validation: PASS (`node scripts/validate_closed_beta.mjs`).
- Step 12 local debug-signed AAB smoke: PASS (`apps/mobile/build/app/outputs/bundle/release/app-release.aab`); this artifact is not Play-uploadable.
- Step 12 signed AAB/Play internal and closed-test validation: BLOCKED until release secrets, Play access, and beta runtime are supplied.
- Version 1.1 Flutter analyze: PASS (`No issues found!`).
- Version 1.1 static Phone OTP/localization contract validation: PASS (`node scripts/validate_version11.mjs`, 29 checks).
- Version 1.1 Provider Portfolio contract validation: PASS (`node scripts/validate_version11.mjs`, 39 checks).
- Version 1.1 No-show contract validation: PASS (`node scripts/validate_version11.mjs`, 48 checks).
- Version 1.1 Job auto-expire contract validation: PASS (`node scripts/validate_version11.mjs`, 55 checks).
- Version 1.1 richer review dimension contract validation: PASS (`node scripts/validate_version11.mjs`, 62 checks).
- Version 1.1 Flutter test: PASS (37 tests passed).
- Provider Portfolio migration: PASS in local Docker reset/lint; Step 11 integration suite remains PASS (19 checks).
- No-show local RPC runner: PASS (`supabase/tests/run_version11_no_show_local.mjs`, 3 checks).
- Job expiry migration: PASS in local Docker reset/lint; expiry local runner passes (`supabase/tests/run_version11_expiry_local.mjs`, 3 checks).
- Review dimension migration: PASS in local Docker reset/lint; review local runner passes (`supabase/tests/run_version11_review_local.mjs`, 4 checks).
- Version 1.1 Android debug APK: PASS (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- Step 3/4/5 static source review: PASS; no runtime Supabase values or service-role key committed.

## Commit ID / rollback point

Step 10 commit: `883dcf0` (`feat: add push-ready notification pipeline`). Step 11 commit: `12d3916` (`feat: add security and resilience checks`). Step 11 runtime validation fix: `9e1c49d` (`fix: validate Supabase security locally`). Step 12 release-prep commit: `716799c` (`feat: prepare closed beta release signing`). Version 1.1 Phone OTP commit: `92db847` (`feat: add phone OTP authentication`). Version 1.1 three-language commit: `11f1a0e` (`feat: add three-language app foundation`). Version 1.1 Provider Portfolio commit: `ad02c18` (`feat: add provider portfolio`). Version 1.1 No-show commit: `46020ab` (`feat: add no-show job marker`). Version 1.1 Job auto-expire commit: `a7c6a89` (`feat: add job auto-expiry worker`). Version 1.1 richer review dimensions commit: `5aafb7c` (`feat: add richer review dimensions`). The paired Version 1.1 docs commit is the current rollback point.

## Next step

Next: Version 1.1 deep business-page translation, FCM provider completion, and real SMS/provider/device verification. Google Play internal/closed testing remains deferred until explicitly requested.
