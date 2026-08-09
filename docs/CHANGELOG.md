# Changelog

## Unreleased — Security hardening

- Hosted mobile builds now fail closed when `APP_ENV=staging` or `production` is missing Supabase runtime values; only development may use the local demo adapter.
- The local mobile run/build script now requires explicit hosted overrides for staging/production and propagates `OFRIVO_APP_ENV` into the APK/runtime.
- Provider Profile validation continues to assert that pending/rejected categories cannot enter `public_job_feed`; the latest category-approval migration also applies the approved-status filter to job access and notification fan-out.

## Unreleased — Step 0 + Step 1

- Added Ofrivo repository layout and local development guidance.
- Added product, screen map, UI, data, security, test, and release contracts.
- Added Flutter fake-data mobile shell and reusable design-system widgets.
- Added Next.js admin layout placeholder.
- Deferred all backend and later-stage product functionality by design.
- Admin lint and production build pass with Next.js 16.3.0.
- Flutter validation is recorded as blocked because the SDK is unavailable in the environment.

## Step 2 — Supabase foundation

- Added the local schema migration with enum-like status types, foreign keys, constraints, indexes, updated-at triggers, safe public views, and audit events.
- Added private Storage bucket definitions and object policies.
- Added RLS policies for profiles, providers, jobs, bids, reviews, reports, notifications, tokens, and events.
- Added transactional `accept_bid`, `start_job`, `complete_job`, and `cancel_job` RPCs.
- Added local-only seed fixtures and SQL security/concurrency test notes.

## Step 3 — Authentication and profiles

- Added runtime Supabase bootstrap using `SUPABASE_URL` and `SUPABASE_ANON_KEY` dart-defines.
- Added Email + Password repository/controller for sign-in, registration, logout, reset, and session restore.
- Added profile upsert/read, suspended-account guard, approved-provider mode guard, and local demo fallback.
- Added Auth repository/profile parsing tests.

## Step 4 — Customer Job Creation

- Added customer job draft model and required-field validation.
- Added category/area selection, private address/contact fields, urgency, service window, budget, and up-to-five photo selection.
- Added fake and Supabase job repositories, private Storage photo upload, draft/preview/publish, My Jobs, Job Detail, and cancellation flow.
- Added customer job controller loading/error states and lifecycle tests.
- Flutter validation was initially blocked until the SDK was prepared; current validation is recorded below.

## SDK preparation — Flutter Android validation

- Prepared Flutter stable 3.44.8 / Dart 3.12.2 with accepted Android SDK licenses.
- Generated the Android host project and locked the Gradle wrapper to the cached 9.1.0 binary distribution.
- Disabled Kotlin incremental compilation for the Windows cross-drive Pub-cache layout.
- `flutter analyze` passes with no issues, all 10 Flutter tests pass, and the debug APK builds successfully.

## Step 5 — Provider Application

- Added shared service category/area options and provider application draft/status models.
- Added Provider Information form, category/area selection, private ID/SSM/certificate evidence, and work-photo selection.
- Added Pending, Approved, Rejected, and Suspended verification status UI.
- Added fake and Supabase provider application repositories with private Storage upload cleanup.
- Added `provider_work_photos` and protected `submit_provider_application` migration/RPC, including server-controlled status transitions.
- Added provider application validation and fake lifecycle tests.
- Flutter validation passes with the prepared SDK; see the SDK preparation entry above.

## Step 6 — Provider Job Feed and Bid

- Added approved-provider feed models, filters, controller, fake repository, and Supabase `public_job_feed` adapter.
- Added category, area, service-date, budget, urgent, no-bids, and sort filters.
- Added safe job detail with private address/contact boundary and signed job-photo support.
- Added bid submission, pending-bid edit, pending-bid withdrawal, and provider-scoped My Bids UI.
- Added the Step 6 feed/view migration, static contract validator, and five fake lifecycle/filter tests.

## Step 7 — Transactional Accept Bid

- Added customer Received Bids and Provider Profile flows with provider-directory mapping.
- Wired customer acceptance to the existing PostgreSQL `accept_bid` RPC; the fake adapter mirrors the atomic state transition for local preview.
- Added selected-bid acceptance, automatic rejection of other pending bids, assigned-job refresh, and concurrency guard tests.
- Added accepted-provider assigned-job loading with full address/contact reveal only after authorization.
- Added notification repository/controller, unread styling, mark-read behavior, and fake/Supabase adapters.
- Added Step 7 RPC/mobile contract validation; Flutter analyze, 18 tests, and Android debug build pass.

## Step 8 — Job Completion, Review, and Report

- Added transactional start, complete, and assigned-job cancellation adapters for fake mode and Supabase RPCs.
- Added review and report drafts, participant-aware Supabase inserts, fake lifecycle behavior, and validation tests.
- Added Job Event Log timeline to customer and provider job details.
- Added review/report routes, completed-job actions, provider start/complete controls, and cancellation confirmation.
- Added Step 8 lifecycle contract validation; Flutter analyze, 21 tests, and Android debug build pass.

## Step 9 — Admin Web

- Replaced the static admin placeholder with a local operations console and login preview.
- Added Dashboard, Provider Verification, Users, Jobs, Bids, Reports, Categories, Areas, Audit Log, and System Settings views.
- Added approve/reject/suspend provider actions, suspend/restore account actions, report review/resolve/dismiss actions, and local audit-event append behavior.
- Added private evidence and job-address admin detail boundaries with production signed-URL/server-guard guidance.
- Added `supabase/tests/validate_step9.mjs`; Admin lint and Next.js production build pass.

## Step 10 — Push Notification

- Added device-token registration/unregistration RPCs, fake/Supabase repositories, runtime token source, and push-registration controller.
- Added new matching job, new bid, bid accepted, verification result, job lifecycle, and job-expiry notification type coverage.
- Added SQL fan-out triggers for published jobs, bids, and verification results plus a scheduled job-expiry queue function; notification rows remain the durable outbox.
- Added unread notification badge, mark-all-read state, provider new-job routing, local demo token fixture, and notification tests.
- Added `supabase/tests/validate_step10.mjs`; Flutter analyze, 23 tests, and Android debug build pass.

## Step 11 — Security and Testing

- Added manual RLS, private Storage, multiple-account, concurrent accept-bid, and invalid-transition scenarios in `step11_security_and_testing.sql`.
- Added image file validation for extension/signature, size, count, duplicate paths, and missing files; customer/provider pickers now reject unsafe selections.
- Added retryable error and offline widgets plus global crash diagnostic capture.
- Added multi-account, image, crash, and widget resilience tests with `supabase/tests/validate_step11.mjs`.
- Added executable local Supabase integration checks and corrected migration ordering, Storage owner type casts, RLS policy recursion, service-role grants, and Auth fixture defaults exposed by Docker Postgres.
- Flutter analyze, 28 tests, Android debug build, and 19 local RLS/Storage/concurrency checks pass; hosted Supabase permission tests remain environment-gated.

## Step 12 — Closed Beta preparation

- Added an Android release-signing guard, ignored keystore contract, and `key.properties.example`; debug signing is permitted only for explicitly marked local smoke builds.
- Added the closed-beta runbook covering signed artifacts, Play internal/closed tracks, test identities/jobs, bug triage, and immutable rollback builds.
- Added a privacy-aware bug report template and `scripts/validate_closed_beta.mjs` readiness checks.
- Permanent application ID, production keystore, Play Console promotion, and real beta accounts remain external gates.

## Version 1.1 — Phone OTP and three-language foundation

- Added E.164 phone normalization and validation shared by demo and Supabase Auth paths.
- Added SMS OTP request and verification through Supabase `signInWithOtp` and `verifyOTP`.
- Added local demo OTP flow (`123456`), phone-only profile seeding, controller state, `/phone-login` route, and login-screen entry point.
- Added Phone OTP repository tests and `scripts/validate_version11.mjs`.
- Added English, Bahasa Melayu, and Chinese language state with local persistence, locale propagation, language picker, translated onboarding/auth copy, and translated shell navigation.
- Deep business screens remain English until their individual copy contracts are migrated; the language switch remains available from onboarding, auth, and the authenticated shell.
- Version 1.1 contract validation now covers 29 checks; Flutter analyze and 32 tests pass.
- Added Provider Portfolio support: approved-provider-only public portfolio view, dedicated public `provider-portfolio` bucket, owner-scoped uploads, public profile URL mapping, and demo/gallery coverage.
- Local Docker reset, schema lint, existing 19-check security integration suite, Flutter analyze, 34 tests, Android debug APK, and 39 Version 1.1 contract checks pass.
- Added `mark_no_show` for assigned/in-progress jobs with participant-derived target identity, duplicate protection, private `job_events` metadata, and a typed `no_show` notification.
- Added fake/controller/UI no-show actions, lifecycle tests, and `supabase/tests/run_version11_no_show_local.mjs`; the local runner passes 3/3 checks.
- Version 1.1 contract validation now covers 48 checks; Flutter analyze, 36 tests, and the Android debug APK pass.
- Added publish-time seven-day expiry defaults and service-only `expire_open_jobs` worker with row locks, pending-bid expiration, `job_expired` event/notification outbox, fake parity, and `supabase/tests/run_version11_expiry_local.mjs`.
- Expiry local runner passes 3/3 checks; Version 1.1 contract validation now covers 55 checks, Flutter analyze and 37 tests pass, and the Android debug APK builds.
- Added required punctuality, quality, and communication review dimensions with 1–5 database constraints, detailed fake/Supabase adapters, and review-screen controls.
- Review local runner passes 4/4 checks; Version 1.1 contract validation now covers 62 checks, Flutter analyze and 37 tests pass, and the Android debug APK builds.
- Extended localization into the customer, provider, and job-lifecycle business pages, including job creation, bids, provider application/feed, reviews, and reports, with English/Bahasa Melayu/Chinese fallback.
- Business localization widget coverage passes; Version 1.1 contract validation now covers 65 checks, Flutter analyze reports no issues, 38 tests pass, and the Android debug APK builds.
- Localized the notification centre and suspended/provider-approval guards, deriving notification titles from typed events while leaving dynamic payload bodies server-supplied.
- Notification/access localization tests pass; Version 1.1 contract validation now covers 67 checks, Flutter analyze reports no issues, 39 tests pass, and the Android debug APK builds.
- Real SMS provider configuration and Google Play distribution remain external follow-up steps.

## 2026-08-05 — Admin local Supabase integration

- Replaced the Admin fake-data runtime with a browser anon-key Supabase client and seeded local Auth login guarded by `profiles.is_admin`.
- Added RLS-protected live Admin reads for users, providers, verification records, jobs, bids, reports, taxonomy, and `admin_audit_events`.
- Added atomic provider/account/report moderation RPCs with attributable audit writes and five-minute verification signed URLs.
- Added `supabase/tests/run_admin_local.mjs`, local Admin environment injection in `scripts/local-dev.ps1`, and 15-check Admin contract validation.
- Admin lint/build, local integration, and browser smoke pass; cloud deployment and device UI validation remain deferred/blocked as documented.

## 2026-08-05 — Local Real-Device Validation

- Added `docs/LOCAL_REAL_DEVICE_RUNBOOK.md`, `docs/LOCAL_DEVICE_TEST_RESULTS.md`, and `scripts/local-dev.ps1` for repeatable local Docker, Admin, Emulator, USB reverse, integration, and APK workflows.
- Added a debug-only Android cleartext policy for the local HTTP Supabase endpoint; production Android configuration remains unchanged.
- Added a production Auth bootstrap guard so Demo OTP cannot be used when `APP_ENV=production` lacks real Supabase runtime configuration.
- Local Supabase reset/lint/health and Docker suites pass: 19 Step 11 checks, 3 no-show checks, 3 expiry checks, and 4 review checks.
- Version 1.1 contract validation passes 68 checks; Flutter analyze and 39 tests pass; the debug APK builds. Admin lint/build pass and `npm audit` reports 0 vulnerabilities.
- Emulator host networking passes, but APK installation is blocked by the current AVD storage; no USB phone was connected. No cloud or paid service was configured.

## Unreleased - 2026-08-06

### Added

- Provider Profile editing with persistent public fields, service areas, portfolio, and availability.
- Provider category approval lifecycle with pending/rejected resubmission, Admin review notes, notifications, audit events, and approved-only feed matching.
- Local integration coverage for profile/RLS/feed/availability behavior.

### Changed

- Added independent Admin desktop, tablet, and phone layout builders. Desktop keeps the existing three-column experience; tablet uses a detail drawer; phone uses a touch-first Job list and full-screen detail flow.
- Added mobile navigation drawer and breakpoint-specific Job detail controls without changing Admin data, RLS, or moderation behavior.

## 2026-08-09 - Phase 1 local security audit

- Started Docker Desktop and validated a clean Supabase migration/seed reset.
- Supabase schema lint passed with no schema errors.
- Local security/lifecycle/Admin/provider-profile integration runners passed: 19 + 3 + 3 + 4 + Admin + 19 checks.
- Confirmed approved-category feed and notification gating, customer/provider isolation, private Storage ownership, Admin authorization, and one-winner bid concurrency at runtime.
- No business-code or migration change was required in this phase.
- Hosted Supabase, real-device UI, dual-device UI, formal history secret scan, SMS, FCM, and paid/cloud services remain deferred or blocked.

## Unreleased - 2026-08-09 Phase 2 account/profile isolation

- Added `provider_profiles.display_name` and a clean migration/backfill so provider business names no longer overwrite customer identity.
- Wrapped the provider application/update RPCs to preserve `profiles.display_name` while updating provider-facing data.
- Scoped Demo Provider jobs and bids to mapped authenticated accounts and removed the unscoped Provider detail fallback.
- Hydrated provider display names in mobile auth/application repositories and separated Provider/Customer naming in the Admin repository.
- Added Flutter regressions for new-account fake-data isolation and a 13-check Phase 2 static validator.
- Local Docker reset/lint/integration pass; Provider Profile integration now passes 22 checks; Flutter 50 tests/APK and Admin lint/build/audit pass.
- Hosted Supabase, physical-device UI, dual-device UI, SMS, FCM, and secret-history scanning remain deferred.

## Unreleased - 2026-08-09 Phase 3 job scheduling and lifecycle hardening

- Added customer owner-scoped editing for draft/open Jobs, with publish/update routing and edit-state UI coverage.
- Added server-side protection against customer expiry tampering and open-to-draft rollback.
- Enforced valid UTC schedule ranges and Malaysia calendar-day constraints while preserving legacy time_window reads.
- Added Phase 3 static and Docker regression runners covering schedule persistence, expiry, legacy compatibility, feed exposure, and assigned-job immutability.
- Local Flutter, Supabase, Docker integration, Admin, and audit validation pass; hosted/device delivery remains deferred.

## Unreleased - 2026-08-09 Phase 4 emulator smoke validation

- Wiped and recovered the medium_phone Android 16/API 36 emulator for local UI testing.
- Verified local Supabase APK installation, Customer/Provider authentication, session restoration, mode switching, profile identity, feed matching, and pre-acceptance address privacy.
- Corrected the auth screen environment label so configured builds identify Local Supabase or a Supabase backend instead of showing the Demo-only hint.
- Recorded the emulator evidence and kept full multi-device lifecycle, hosted, SMS, and FCM gates explicitly pending/deferred.
