# Release Checklist

## Step 0 + Step 1

- [x] Flutter analyze passes (Flutter 3.44.8).
- [x] Flutter tests pass (10 tests).
- [x] Android debug build passes (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- [x] Admin lint passes.
- [x] Admin production build passes.
- [x] No Supabase/Firebase credentials committed.
- [x] No hosted migration or real bucket applied.
- [x] Public-feed privacy rules remain documented.
- [x] Project status and changelog updated.
- [x] Step 1 commit recorded with rollback point.

## Step 2 database foundation

- [ ] Migration applies to a clean Supabase local instance.
- [ ] Seed applies after migration.
- [ ] RLS privacy scenarios pass.
- [ ] Storage private-bucket scenarios pass.
- [ ] Concurrent `accept_bid` scenario passes.
- [ ] Step 2 commit and rollback point recorded.

## Step 3 authentication and profiles

- [x] Flutter Auth unit/widget tests pass.
- [ ] Runtime Supabase defines are supplied only through local/CI secrets.
- [ ] Register/login/session restore works against `ofrivo-dev`.
- [ ] Profile RLS tests pass.
- [ ] Suspended account and Provider Mode guards pass.

## Step 4 customer job creation

- [x] Job form validation tests pass.
- [ ] Draft save and publish work in local demo mode.
- [ ] Supabase insert, private job-photo upload, and draft-to-open transition pass against an isolated project.
- [ ] My Jobs and Job Detail show only the authenticated customer's jobs.
- [ ] Cancellation uses `cancel_job` and rejects non-cancellable states.
- [x] No service-role key or hosted Supabase values committed.

## Step 5 provider application

- [x] Provider application validation tests pass.
- [ ] Categories and areas persist only for the authenticated provider.
- [ ] Identity evidence and work photos upload to the private verification bucket.
- [ ] `submit_provider_application` transitions the provider to pending without allowing client-side approval.
- [ ] Pending, approved, rejected, and suspended UI states render with the correct next action.
- [ ] Supabase RLS and Storage scenarios pass against an isolated local project.
- [x] No service-role key or hosted Supabase values committed.

## Step 6 provider job feed and bids

- [x] Approved-provider feed loads only open jobs from the safe public view.
- [x] Category, area, service date, budget, urgent, no-bid, and sort filters pass fake-data tests.
- [x] Job detail hides full address, phone, WhatsApp, and exact GPS until acceptance.
- [x] Provider can submit, edit, and withdraw a pending bid.
- [x] My Bids shows only the authenticated provider's bid records.
- [x] Step 6 static migration/mobile contract validation passes.
- [x] No service-role key or hosted Supabase values committed.

## Step 9 Admin Web

- [x] Admin login preview and sign-out flow render.
- [x] Dashboard, provider verification, users, jobs, bids, reports, taxonomy, settings, and audit views render.
- [x] Provider/account/report moderation actions append local audit events.
- [x] Step 9 static contract validation passes.
- [x] Admin lint and production build pass.
- [ ] Production admin Auth claims, RLS-backed repositories, signed evidence URLs, and server-side audit writes are configured.

## Step 10 Push Notification

- [x] Device-token fake/Supabase repositories and authenticated registration RPCs exist.
- [x] New job, new bid, verification result, lifecycle, and job-expiry notification contracts exist.
- [x] Notification centre shows unread state and supports mark-all-read.
- [x] Step 10 static contract validation passes.
- [x] Flutter analyze, tests, and Android debug build pass.
- [ ] Native FCM provider, scheduled expiry worker, and production delivery credentials are configured.

## Step 11 Security and Testing

- [x] Step 11 static security/testing contract validation passes.
- [x] Flutter analyze passes with no issues.
- [x] Flutter test suite passes (28 tests).
- [x] Android debug APK builds successfully.
- [x] Image signature, size, count, duplicate, and missing-file validation is wired to pickers.
- [x] Error retry, offline state, crash diagnostic, and multi-account smoke tests exist.
- [x] RLS, private Storage, account isolation, bid eligibility, invalid transitions, and concurrent acceptance scenarios pass against the isolated local Docker Supabase runtime (19 checks).
- [ ] The same permission and concurrency checks pass against the hosted beta Supabase project.

## Step 12 Closed Beta

- [x] Release signing guard and `key.properties.example` are documented; real keystore remains outside git.
- [x] Closed-beta runbook defines signed APK/AAB, Play internal/closed tracks, tester identities/jobs, bug triage, and rollback.
- [x] Bug report template requires build, device, reproduction, privacy redaction, and retest evidence.
- [x] Step 12 static readiness validator passes.
- [ ] Permanent Android application ID is selected and registered in Google Play Console.
- [ ] Production upload keystore is provisioned in the secret manager and a signed AAB is archived with SHA-256.
- [ ] Google Play internal test passes with the isolated beta project and approved test accounts.
- [ ] Google Play closed test is promoted without rebuilding the immutable artifact.

## Version 1.1 Phone OTP

- [x] E.164 phone normalization and validation are shared by demo and Supabase Auth paths.
- [x] Local demo OTP request/verify flow uses the documented `123456` code and rejects stale/invalid requests.
- [x] Supabase SMS request/verify adapter and phone-only profile fallback are implemented.
- [x] `/phone-login` route, login entry point, loading/error/info states, and change-number action render.
- [x] Three-language foundation supports English, Bahasa Melayu, and Chinese in onboarding, auth, and shell navigation.
- [x] Selected language persists locally and propagates to `MaterialApp.locale`.
- [x] Version 1.1 static contract validation passes (`29` checks).
- [x] Flutter analyze and tests pass (`32` tests).
- [x] Provider Portfolio separates public work photos from private verification evidence.
- [x] Approved-provider portfolio view, owner-scoped Storage writes, demo fixtures, URL mapping, and gallery fallbacks are implemented.
- [x] Local database reset/lint, Step 11 security integration (19 checks), and Version 1.1 contract validation (39 checks) pass.
- [x] Android debug APK builds with the portfolio UI.
- [x] No-show RPC enforces assigned/in-progress state, participant-derived target, bounded reason, and duplicate guard.
- [x] Fake/UI no-show actions and typed `no_show` notifications are implemented.
- [x] Local No-show RPC runner passes 3 checks; Version 1.1 contract validation now passes 48 checks.
- [x] Android debug APK builds with the No-show UI.
- [x] Publish-time expiry defaults and service-only `expire_open_jobs` worker are implemented.
- [x] Expiry worker locks due open jobs, expires pending bids, and writes event/notification outbox rows atomically.
- [x] Local expiry runner passes 3 checks; Version 1.1 contract validation now passes 55 checks.
- [x] Android debug APK builds with the `job_expired` notification mapping.
- [x] Reviews collect punctuality, quality, and communication scores in addition to the overall rating.
- [x] New review dimension scores are required and constrained to 1–5; legacy rows receive a safe migration default.
- [x] Local review runner passes 4 checks; Version 1.1 contract validation now passes 62 checks.
- [x] Android debug APK builds with the detailed review controls.
- [x] Customer, provider, and lifecycle business pages use persisted English, Bahasa Melayu, and Chinese localization keys with a safe fallback.
- [x] Business localization widget coverage passes; Version 1.1 contract validation now passes 65 checks.
- [x] Flutter analyze reports no issues, 38 Flutter tests pass, and the Android debug APK builds.
- [ ] Remaining Admin Web and notification copy is migrated and reviewed in all three languages.
- [ ] Supabase SMS provider and sender configuration are supplied for real-device verification.
- [ ] Google Play distribution remains deferred by current scope.

## Before any beta

- [ ] RLS and storage permission tests pass.
- [ ] Transactional bid acceptance concurrency test passes.
- [ ] Privacy Policy, Terms, provider agreement, retention, deletion, and appeals flows exist.
- [ ] Test accounts and rollback build are documented.
