# Project Status

## Current stable version

Version 1.1 Phone OTP, three-language foundation, Provider Portfolio, No-show marker, Job auto-expire, richer review dimensions, deep business-page localization, and notification/access-state localization (local Docker validation complete; real SMS/FCM delivery remains configuration-gated).

## Current status (2026-08-05)

Local automated validation is complete. The reviewed baseline is `61e112a` with rollback point `bd59bbb`; this Admin integration change is the next local-only increment on `master`. Local Supabase, schema/RLS/Storage/RPC rebuilds, Docker integration, Flutter checks/build, Admin lint/build, and the local Admin browser smoke test pass. Android UI/device E2E remains `BLOCKED` by the current emulator storage shortage and the absence of a connected USB phone. Cloud and paid services remain explicitly deferred.

## Current objective

Continue Version 1.1 hardening while preserving account privacy, transactional invariants, actionable error states, and runtime-only secrets. Core entry/auth/navigation, customer/provider/lifecycle business pages, notification centre, and access guards now support English, Bahasa Melayu, and Chinese with safe fallback; approved-provider portfolio photos are separated from private evidence; no-show reports are participant-derived and duplicate-safe; open jobs now have a service-only expiry worker with event/notification outbox writes; reviews now capture punctuality, quality, and communication dimensions. Remaining Admin Web/server-generated notification copy review and external delivery configuration are tracked separately. Google Play distribution is intentionally deferred for now.

## Local-only validation result (2026-08-05)

- Local Real-Device Validation is the active objective. No Cloudflare, Vercel, Supabase Cloud, Google Play, paid SMS, real FCM, payment, maps, chat, or new feature work was performed.
- `scripts/local-dev.ps1` and `docs/LOCAL_REAL_DEVICE_RUNBOOK.md` now provide reproducible start/status/health/reset/lint/integration/Admin/Emulator/device/APK commands without copying secrets into source.
- Supabase local `start`, `status`, `db reset`, `db lint`, and API/Auth, REST, Studio, and Mailpit health checks pass on ports `54420`-`54427`. Core DB/Auth/REST/Storage/Realtime services recover after restart; Windows Docker Analytics/Vector warnings are optional and do not affect the tested core paths.
- Docker integration runners pass 19 Step 11 checks, 3 no-show checks, 3 expiry checks, 4 review-dimension checks, and the Admin local Auth/data/Storage/RPC/audit runner. Admin browser smoke confirms seeded Auth, live queues, signed-evidence boundary, and a moderation action. Admin lint, production build, and `npm audit` pass with 0 vulnerabilities.
- Version 1.1 contract validation passes 68 checks; Flutter analyze is clean, all 39 Flutter tests pass, and the debug APK builds.
- Emulator host connectivity to `10.0.2.2:54421` passes, but the current AVD cannot install the APK because of insufficient `/data` storage. No emulator wipe was performed. No USB phone was connected, so device UI flows remain explicitly blocked rather than claimed as passed.

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
- Version 1.1 deep business-page localization added across customer, provider, and lifecycle flows with persisted three-language keys, widget coverage, and safe fallback behavior.
- Version 1.1 notification-center and access-state localization added with typed notification titles, localized empty/read states, and account/provider guards.
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
- Step 9 Admin Web console now authenticates through local Supabase Auth and loads live RLS-protected users, providers, jobs, bids, reports, taxonomy, and audit records.
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
- Admin Web local Supabase integration is complete for this phase: browser anon-key Auth, `is_admin` profile guard, signed verification URLs, atomic moderation RPCs, and attributable audit events are wired to Docker Supabase. Production/cloud deployment remains out of scope.
- Hosted Supabase RLS/Storage/multi-account/concurrency scenarios remain pending; the equivalent isolated local Docker run passes, but no cloud project is connected.
- Closed Beta remains externally gated by a permanent Android application ID, production upload keystore, Google Play Console access, isolated beta project, and real tester accounts.
- Real Phone OTP delivery remains externally gated by Supabase SMS provider/sender configuration; the local demo path is deterministic and offline.
- Remaining Admin Web and server-generated notification body copy still needs migration and review in all three languages; mobile customer/provider/lifecycle and notification-center surfaces are covered.
- Provider Portfolio hosted rollout still needs the migration applied to the target Supabase project and real public image review; local Docker reset/lint passed.
- No-show hosted rollout still needs the migration applied to the target Supabase project and real participant/device review; local RPC runner passes.
- Job auto-expire hosted rollout still needs the migration applied to the target Supabase project and a managed scheduler/service-role runtime; local expiry runner passes.
- Richer review dimensions hosted rollout still needs the migration applied to the target Supabase project and real participant/device review; local runner passes.

## Known issues / environment

- Android SDK and Docker Desktop are available; `adb` is on PATH but no Android device is currently connected.
- Admin commands may require `npm.cmd` on this PowerShell host.
- The `medium_phone` AVD has insufficient install space (approximately 543 MB free after cache trim); use an approved larger AVD or a USB device before claiming UI/device E2E.
- Supabase Vector may restart on Windows when Docker daemon log access is unavailable; Analytics/Vector are optional for this local core validation. The API/Auth route was recovered with a local stop/start and health then passed.

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
- Step 9 Admin Web static contract validation: PASS (`node supabase/tests/validate_step9.mjs`, 15 checks).
- Step 9 Admin lint: PASS (`npm.cmd run lint`).
- Step 9 Admin production build: PASS (`npm.cmd run build`, static `/` output).
- Admin local integration runner: PASS (Auth, real data, signed URL, moderation RPCs, audit writes, fixture restoration).
- Admin browser smoke: PASS (`http://localhost:3000`, seeded Admin login, live provider queue, approval action).
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
- Version 1.1 business-page, notification/access, and production-auth guard validation: PASS (`node scripts/validate_version11.mjs`, 68 checks).
- Version 1.1 Flutter test: PASS (39 tests passed, including business and notification fallback coverage).
- Provider Portfolio migration: PASS in local Docker reset/lint; Step 11 integration suite remains PASS (19 checks).
- No-show local RPC runner: PASS (`supabase/tests/run_version11_no_show_local.mjs`, 3 checks).
- Job expiry migration: PASS in local Docker reset/lint; expiry local runner passes (`supabase/tests/run_version11_expiry_local.mjs`, 3 checks).
- Review dimension migration: PASS in local Docker reset/lint; review local runner passes (`supabase/tests/run_version11_review_local.mjs`, 4 checks).
- Version 1.1 Android debug APK: PASS (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- Step 3/4/5 static source review: PASS; no runtime Supabase values or service-role key committed.

### Current local validation evidence

- `node scripts/validate_version11.mjs`: PASS, 68 checks.
- `F:\Dev\FlutterSDK\bin\flutter.bat analyze --no-pub`: PASS; no issues.
- `F:\Dev\FlutterSDK\bin\flutter.bat test --no-pub`: PASS; 39 tests.
- `F:\Dev\FlutterSDK\bin\flutter.bat build apk --debug --no-pub`: PASS.
- `apps/admin`: `npm.cmd run lint`, `npm.cmd run build`, and `npm.cmd audit`: PASS; audit reports 0 vulnerabilities.
- Local Docker runners: PASS, 19 + 3 + 3 + 4 checks.
- Emulator: network PASS; APK installation and runtime UI BLOCKED by AVD storage. Physical USB device: BLOCKED (none connected).

## Commit ID / rollback point

Reviewed baseline: `61e112a`; rollback point: `bd59bbb`. This change is the local Admin integration commit `feat: connect Ofrivo admin to local Supabase`; the exact commit hash is reported in the handoff.

Step 10 commit: `883dcf0` (`feat: add push-ready notification pipeline`). Step 11 commit: `12d3916` (`feat: add security and resilience checks`). Step 11 runtime validation fix: `9e1c49d` (`fix: validate Supabase security locally`). Step 12 release-prep commit: `716799c` (`feat: prepare closed beta release signing`). Version 1.1 Phone OTP commit: `92db847` (`feat: add phone OTP authentication`). Version 1.1 three-language commit: `11f1a0e` (`feat: add three-language app foundation`). Version 1.1 Provider Portfolio commit: `ad02c18` (`feat: add provider portfolio`). Version 1.1 No-show commit: `46020ab` (`feat: add no-show job marker`). Version 1.1 Job auto-expire commit: `a7c6a89` (`feat: add job auto-expiry worker`). Version 1.1 richer review dimensions commit: `5aafb7c` (`feat: add richer review dimensions`). Version 1.1 business localization commit: `4db264a` (`feat: localize business pages`). Version 1.1 notification localization commit: `665ec74` (`feat: localize notification center`). The paired Version 1.1 docs commit is the current rollback point.

## Next step

Next: provide an authorized USB Android phone or an approved larger AVD, then run the documented on-device workflow. Real SMS, FCM delivery, Supabase Cloud, Cloudflare, Vercel, and Google Play remain deferred until explicitly requested.

## 2026-08-06 Provider Profile and category approval flow

- Provider Profile card chevron now opens `/provider/profile/edit` with real profile data; display name, bio, phone/WhatsApp, areas, portfolio, and availability are persisted through authenticated RPCs.
- `provider_categories` now records `pending | approved | rejected` plus submission/review metadata. Existing rows default to approved; newly added categories stay out of the feed until Admin approval.
- Added `submit_provider_category_changes`, `review_provider_category`, `update_provider_profile`, and `set_provider_availability` with server-side validation, RLS/privilege guards, audit events, and provider notifications.
- Provider feed and open-job reads require approved category, matching area, and `is_available`; accepted/assigned jobs remain readable when availability is turned off.
- Admin now has a live Category Requests view with provider/category detail, note input, approve/reject actions, and audit-backed refresh.
- Local Docker reset and the new Provider Profile integration runner pass. Flutter analyze and tests pass; Admin lint/build pass.
- Cloud/paid services remain unchanged. Physical-device UI and dual-device UI validation remain separate gates.
## Final validation snapshot for this change (2026-08-06)

- Local Supabase health: API/Auth, REST, Studio, and Mailpit PASS; `db reset` and `db lint` PASS.
- Local integration: Step 11 (19), no-show (3), expiry (3), review (4), Admin (6), Provider Profile (19) PASS.
- Static contracts: Version 1.1 (68) and Provider Profile (15) PASS.
- Flutter analyze PASS; Flutter test PASS (42 tests); debug APK PASS.
- Admin lint PASS; production build PASS; `npm audit --audit-level=high` reports 0 vulnerabilities.
- Isolated `ofrivo-staging` migration `20260806000100_provider_profile_category_approval.sql` applied; read-only provider category metadata API smoke PASS.

## 2026-08-06 Admin dual-layout responsive shell

- Desktop (>=1024px) keeps the existing sidebar + list + detail workspace through a dedicated desktop builder.
- Tablet (768–1023px) keeps the sidebar and opens Job Detail in a right-side drawer so the list remains visible.
- Phone (<768px) uses a separate mobile header/navigation drawer and a touch-first Job list; tapping a Job opens a full-screen detail view with a back action.
- Desktop Job detail remains visible beside the list; no desktop table-to-card replacement or sidebar collapse was introduced.
- Admin static validation now covers 20 checks; Admin lint and production build pass.

## Current Phase 1 status (2026-08-09)

Phase 1 local runtime security validation is complete on the clean Supabase Docker stack. No migration, policy, or client-code defect was found, so no business-code change was required.

- Baseline commit before this phase: 33c04be.
- supabase db reset and supabase db lint pass.
- Local integration passes: Step 11 19, no-show 3, expiry 3, review dimensions 4, Admin live/RPC/Storage, and provider-profile/category 19.
- Cross-account job/address/notification checks, private Storage ownership, approved-category feed/notification gating, Admin authorization, and accept-bid concurrency pass locally.
- Flutter baseline remains analyze PASS, 48 tests PASS, 69 Version 1.1 checks PASS, 15 provider-profile checks PASS, and debug APK PASS.
- Admin lint/build and npm audit remain PASS with 0 vulnerabilities.
- Hosted Supabase, formal history secret scan, physical-device UI, dual-device UI, SMS, FCM, and cloud deployment remain BLOCKED or deferred.

Next phase: account/profile and product-logic edge-case audit, followed by device validation. Do not treat local runtime PASS as hosted or real-device PASS.

## Current Phase 2 status (2026-08-09)

Account/profile and product-logic audit is complete locally on a clean Docker reset.

- Provider business identity is stored in `provider_profiles.display_name`; customer identity remains in `profiles.display_name`.
- Provider application/update RPCs preserve the customer-facing name while updating the provider-facing name.
- Demo Provider jobs/bids and Provider detail routes are scoped to the authenticated Demo account; unrelated/new accounts receive no fake Provider data.
- Admin live data now uses provider business names for Provider records and customer names for Jobs/Bids/Users.
- Local integration: PASS; Provider Profile runner now passes 22 checks.
- Static Phase 2 validator: PASS, 13 checks. Flutter analyze: PASS. Flutter tests: PASS, 50 tests. Debug APK: PASS.
- Admin lint/build: PASS. `npm audit --audit-level=high`: 0 vulnerabilities.

Hosted Supabase, USB physical-device UI, dual-device UI, SMS, FCM, and secret-history scanning remain separate gates and are not claimed as PASS.

## Current Phase 3 status (2026-08-09)

Job scheduling and lifecycle hardening is complete on the local Docker stack.

- Added owner-scoped editing for draft/open Jobs and a separate mobile edit route; assigned, in-progress, completed, and cancelled Jobs remain immutable to customers.
- Database trigger blocks customer expiry tampering and open-to-draft rollback; trusted service-role runners retain the required server-side helper grants.
- Schedule endpoints are stored as UTC, require end later than start, and must remain on the same Malaysia calendar day; the legacy time_window fallback remains readable.
- Local evidence: Phase 3 runner 14 checks, Version 1.1 validator 69 checks, Flutter 53 tests/analyze/APK, DB reset/lint, and Admin lint/build/audit all pass.
- Hosted Supabase, cloud deployment, USB physical-device UI, dual-device UI, SMS, FCM, and formal history secret scanning remain deferred or blocked.

Next phase: review this local baseline, then perform explicitly authorized hosted or real-device validation.

## Current Phase 4 status (2026-08-09)

The authorized Android Emulator gate is partially complete on the local Docker stack.

- medium_phone was wiped and booted successfully with approximately 5.0 GB free storage; the local Supabase-configured APK installed and initialized Supabase.
- Customer login/session restore, Provider login, same-account mode switching, Provider profile identity, feed matching, and pre-acceptance address privacy passed on emulator-5554.
- Fixed the login environment label so configured builds show Local Supabase or Supabase backend instead of the misleading Demo-only message.
- Flutter analyze/tests and Phase 3 static validation remain PASS after the UI fix.
- Full UI lifecycle, USB physical device, dual-device UI, hosted Supabase, SMS, FCM, and cloud deployment remain separate gates.

Do not promote this emulator smoke evidence to a complete E2E or hosted release claim.

## Current Phase 5 status (2026-08-09)

The local Docker stack now has a complete single-emulator Customer-to-Provider lifecycle pass.

- Customer created a real scheduled Job with a 10:00 AM–11:00 AM range; UTC persistence passed, and the rebuilt APK now derives display text from UTC endpoints (Asia/Kuala_Lumpur rendered 6:00 PM–7:00 PM for the stored 10:00Z–11:00Z row).
- Provider bid, Customer acceptance, address unlock, start, complete, reciprocal reviews, and safety report all passed on `emulator-5554`.
- Fixed the ambiguous PostgREST `jobs` embed by selecting `bids_job_id_fkey` explicitly in both Customer and Provider bid reads.
- Fixed Customer Job-card offer counts; the rebuilt APK now renders the persisted count instead of a hard-coded zero.
- Flutter analyze, 53 Flutter tests, and debug APK build pass after these fixes.
- Docker integration runners pass again: Step 11 (19), no-show (3), expiry (3), review (4), Admin audit (6), Provider Profile (22), and Phase 3 (14).
- Admin lint, production build, and `npm audit --audit-level=high` pass (0 vulnerabilities).
- Photo-upload UI, USB physical-device UI, dual-device UI concurrency, hosted Supabase, SMS, FCM, and cloud deployment remain separate gates.

Do not promote this result to a hosted or external-beta release claim.

## Current Phase 6 status (2026-08-09)

- Corrected the schedule display defect found when the emulator was changed from GMT to `Asia/Kuala_Lumpur`: UI text now derives from `scheduled_at` and `scheduled_end_at`, not stale `time_window` text.
- Rebuilt APK verification rendered the same `10:00Z–11:00Z` row as `6:00 PM–7:00 PM` on the Malaysia-time emulator.
- Flutter analyze, 53 tests, and debug APK build pass after the timezone fix.
- Physical-device, dual-device, photo-upload, hosted Supabase, SMS, FCM, and cloud deployment remain separate gates.
