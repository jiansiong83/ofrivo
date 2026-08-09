# Test Plan

## Step 0 + Step 1 checks

- Flutter static analysis and unit/widget tests.
- Android debug build with the prepared Flutter SDK.
- Admin lint and production build.
- Manual route smoke test for public, customer, provider, and Admin Web preview flows.
- Search the repository for forbidden real credentials and backend URLs.

## Step 2 SQL checks

- Run `node supabase/tests/validate_step2.mjs` for migration/seed contract checks.
- Apply the migration and seed to an isolated Supabase local instance when the CLI/Docker runtime is available.
- Run the scenarios in `supabase/tests/step2_security_and_concurrency.sql` with the listed test identities.
- Confirm the two-device accept-bid scenario leaves exactly one accepted bid and one assigned job.

## Step 3 Auth checks

- Fake repository restores a demo session without network access.
- Register, login, logout, forgot-password, and session-restore states expose loading/error/info feedback.
- Runtime configuration never accepts or embeds a service-role key.
- Suspended profile is blocked from normal app routes.
- Non-approved provider cannot enter Provider Mode.

## Step 4 Customer Job checks

- Job draft validation rejects missing title, description, address, phone, invalid budget, and more than five photos.
- Fake repository covers save as draft, publish, load, and cancel lifecycle behavior.
- Post Job form carries category/area IDs and private contact fields into preview and repository payloads.
- Supabase repository inserts a draft, uploads job photos to the private `job-photos` bucket, and transitions draft to open only after the insert succeeds.
- Customer cancellation uses the transactional `cancel_job` RPC and only enables for cancellable job states.
- Flutter unit/widget tests and Android build pass with the prepared SDK.

## Step 5 Provider Application checks

- Provider draft validation requires display name, bio, at least one category/area, ID front/back, and selfie; evidence and work-photo limits are enforced.
- Fake repository transitions a not-applied profile to pending after submission.
- Supabase submission uploads private verification evidence, calls `submit_provider_application`, and cleans up uploaded files if the transaction fails.
- SQL policy prevents direct client insertion of approved provider or verification states; status changes are server-controlled.
- Pending, approved, rejected, and suspended status states expose clear next actions and never reveal verification files publicly.

## Step 6 Provider Feed and Bid checks

- Safe feed mapping exposes category, area, public location, budget, schedule, urgency, bid count, and signed job photos without full address/contact fields.
- Fake feed filters cover category, area, service date, budget range, urgent-only, no-bids-only, newest, highest budget, and soonest service.
- Provider bid validation requires a positive amount, available time, and inclusions; optional exclusions/materials/message fields retain their limits.
- Fake repository covers a provider's active bid edit, new bid submission, and pending bid withdrawal without exposing another provider's bid amount.
- Widget flow exposes protected address messaging, submit/edit actions, and My Bids status/action states.

## Step 7 Transactional Accept Bid checks

- Received Bids loads all offers for a customer-owned job and links each offer to its public provider profile.
- Customer acceptance calls `accept_bid`; the selected bid becomes accepted, competing pending bids become rejected, and the job becomes assigned.
- A second acceptance is rejected after the job leaves `open`, matching the row-lock/transaction contract.
- Assigned provider queries return full address/contact only for the accepted provider; public feed mapping remains address-safe.
- Notifications load unread/read state, mark items read, and route job references to the relevant job detail.
- Run `node supabase/tests/validate_step7.mjs`, Flutter analyze/test, and Android debug build.

## Step 8 Job Completion, Review, and Report checks

- Only the accepted provider can start an assigned job; customers and the accepted provider can complete an in-progress job.
- Assigned-job cancellation uses `cancel_job` and rejects invalid states or non-participants.
- Completed jobs expose one review action per participant, enforce 1–5 stars and comment limits, and preserve the unique reviewer/job rule.
- Reports require a reason and useful description, route to the safety team, and keep participant IDs server-derived in Supabase mode.
- Job Event Log displays transaction events without exposing private fields.
- Run `node supabase/tests/validate_step8.mjs`, Flutter analyze/test, and Android debug build.

## Step 9 Admin Web checks

- Local Admin login uses seeded Supabase Auth and an active `profiles.is_admin` guard; sign-out returns to the login screen.
- Admin loads real users through `admin_list_users` and real provider profiles, verification rows, jobs, bids, reports, taxonomy, and audit rows through RLS.
- Dashboard queue counts navigate to Pending Providers, Reports, and Audit Log.
- Provider verification actions call atomic local RPCs; private evidence is served only through five-minute signed URLs.
- Users covers suspend/restore; Jobs exposes private address only in the admin detail; Bids show admin-scoped offer monitoring.
- Reports cover reviewing, resolving, and dismissing; each moderation mutation appends an attributable audit event.
- Run `node supabase/tests/validate_step9.mjs`, `npm.cmd run lint`, `npm.cmd run build`, and `node supabase/tests/run_admin_local.mjs` with local status env values.

## Step 10 Push Notification checks

- Fake device-token registration stores a platform-labelled token and unregister removes only that token.
- Runtime token input is optional; missing token does not block the authenticated app or inbox.
- Notification mapping covers new job, new bid, bid accepted, job assigned, verification result, lifecycle, and job-expiry events.
- Notification centre shows unread count, supports individual read and mark-all-read, and routes provider new-job references to the safe feed detail.
- SQL fan-out creates user-scoped rows for matching providers/customers; expiry queue is idempotent within the scheduler window.
- Run `node supabase/tests/validate_step10.mjs`, Flutter analyze/test, and Android debug build.

## Step 11 Security and Testing checks

- Run `node supabase/tests/validate_step11.mjs` and the Flutter analyze/test/APK commands.
- In the local Docker Supabase runtime, run `supabase/tests/run_step11_local.mjs` for Auth, RLS, private Storage, account isolation, invalid transitions, and concurrent bid acceptance; keep `step11_security_and_testing.sql` as the manual/session checklist for hosted verification.
- Confirm the local run reports 19 passing integration checks and that the migration applies cleanly from a reset database.
- Run `npx.cmd --yes supabase@2.109.1 db lint` and require `No schema errors found` before promotion.
- Confirm the customer/provider pickers reject spoofed extensions, unsupported signatures, oversized files, duplicate paths, and missing files.
- Confirm `ErrorState` retries the failed loader, `OfflineState` communicates recoverability, and the global crash reporter captures uncaught Flutter/async errors without storing secrets.
- Confirm no `service_role` value or hosted backend secret is present in mobile/admin source.

## Step 12 Closed Beta checks

- Run `node scripts/validate_closed_beta.mjs`, Flutter analyze, and Flutter test before creating a release artifact.
- Confirm a normal `flutter build appbundle --release` refuses to run without `android/key.properties`; use `OFRIVO_ALLOW_DEBUG_RELEASE_SIGNING=true` only for local smoke validation.
- For a real beta artifact, verify the permanent application ID, production upload keystore, version code, AAB SHA-256, Git commit, and build date in the release ticket.
- Execute the internal-test and closed-test paths in `docs/CLOSED_BETA_RUNBOOK.md` with isolated test identities and deterministic jobs; promote the same immutable AAB without rebuilding.
- Use `docs/BUG_REPORT_TEMPLATE.md` for every tester issue and redact credentials, tokens, private evidence, and personal contact data before sharing evidence.

## Version 1.1 Phone OTP checks

- Phone input normalizes spaces, punctuation, and `00` prefixes before validation; reject values outside the E.164 `+` prefix and 8–15 digit range.
- Demo mode sends a local code request, requires a fresh request before verification, accepts only `123456`, and maps the authenticated phone into the session/profile state.
- Supabase mode calls `signInWithOtp(phone: ...)` and `verifyOTP(..., type: OtpType.sms)` without exposing a service-role key.
- Phone-only users receive a safe profile seed identity when no email is present.
- `/login` exposes the phone sign-in entry point; `/phone-login` renders send, verify, change-number, loading, error, and info states.
- Run `node scripts/validate_version11.mjs`, Flutter analyze, Flutter test, and the Android debug build. Real SMS delivery remains gated on Supabase provider configuration.

## Version 1.1 Three-language checks

- Language picker exposes English, Bahasa Melayu, and Chinese from onboarding, auth screens, and the authenticated shell.
- Language changes rebuild onboarding/auth/navigation copy and propagate the selected `Locale` to `MaterialApp`.
- The selected language persists as a locale code through `shared_preferences`; a missing/unavailable preferences plugin keeps an in-memory selection without blocking startup.
- Translation tests cover the three onboarding variants and English fallback behavior; business-page coverage is tracked in the dedicated checks below.
- Run `node scripts/validate_version11.mjs`, Flutter analyze, Flutter test, and the Android debug build after adding a translated feature surface.

## Version 1.1 Provider Portfolio checks

- Provider application uploads work photos to the public `provider-portfolio` bucket; identity evidence and certificates remain in private `provider-verifications`.
- Storage write policy permits only the provider's own folder (or admin); public reads expose no verification, contact, or account fields.
- `public_provider_portfolio` returns paths only for active approved providers; the mobile repository converts those paths to public URLs and tolerates a hosted view rollout without breaking profile loading.
- Customer Provider Profile and provider-mode profile render a placeholder for local demo paths and a network image with an error fallback for public URLs.
- Run `npx.cmd --yes supabase@2.109.1 db reset --yes`, `npx.cmd --yes supabase@2.109.1 db lint`, `node supabase/tests/run_step11_local.mjs`, `node scripts/validate_version11.mjs`, Flutter analyze/test, and the Android debug build.

## Version 1.1 No-show checks

- Only the customer or accepted provider can mark the other participant as a no-show while the job is `assigned` or `in_progress`; open/completed/cancelled jobs reject the action.
- The server derives the reported user from the accepted bid and rejects duplicate no-show markers for the same participant; clients cannot supply an arbitrary target identity.
- The RPC writes a participant-visible `job_events` record with bounded reason metadata and sends a user-scoped `no_show` notification.
- Fake mode mirrors authorization, duplicate protection, event metadata, and notification behavior; the lifecycle UI exposes a confirmation action for both roles.
- Run `node supabase/tests/run_version11_no_show_local.mjs` and require all 3 checks, in addition to the full reset/lint and Step 11 security suite.

## Version 1.1 Job auto-expire checks

- Publishing a draft with no expiry assigns a seven-day offer window; already-open jobs retain their explicit expiry and assigned/in-progress jobs are never expired by this worker.
- `expire_open_jobs` is bounded to 1–500 rows, uses `FOR UPDATE SKIP LOCKED`, and is executable only by `service_role`; browser/anon calls are rejected.
- Each expired open job moves pending bids to `expired`, writes one `job_expired` event, and queues one customer-scoped `job_expired` notification in the same transaction.
- Fake customer mode expires only due open jobs and emits matching local event/notification fixtures.
- Run `node supabase/tests/run_version11_expiry_local.mjs` and require all 3 checks, in addition to reset/lint, the Step 11 security suite, and the Version 1.1 contract validator.

## Version 1.1 Richer review dimension checks

- Completed-job review screens collect an overall rating plus punctuality, quality, and communication scores, each from 1–5, and preserve the optional comment limit.
- Fake and Supabase adapters persist and map all three dimension fields; the existing participant trigger and one-review-per-participant rule remain active.
- Database migration backfills legacy rows to `5` and removes insert defaults so new clients must submit all dimensions explicitly.
- Run `node supabase/tests/run_version11_review_local.mjs` and require all 4 checks, in addition to reset/lint, the Step 11 security suite, and the Version 1.1 contract validator.

## Version 1.1 Business-page localization checks

- Customer job creation, My Jobs, bids, provider application/feed, assigned-job lifecycle, review, and report surfaces resolve copy through the business localization map for English, Bahasa Melayu, and Chinese.
- Notification centre titles, unread/read states, empty state, suspended-account state, and provider-approval guard resolve through the same map; dynamic notification bodies remain payload fixtures for later server-side translation review.
- Changing the persisted language rebuilds the active business screen; an unknown business key returns the key safely rather than throwing or changing authorization state.
- Run the business localization widget test together with `node scripts/validate_version11.mjs`, Flutter analyze, Flutter test, and the Android debug build; the current baseline is 68 contract checks and 39 Flutter tests.

## Local Real-Device Validation (2026-08-05)

- Run the local stack only through `scripts/local-dev.ps1` on the repository's custom ports `54420`-`54427`; require `status`, `health`, `db reset`, and `db lint` to pass before app tests.
- Run `-Command integration` so the Step 11, no-show, expiry, and review runners receive ephemeral local credentials without copying a service-role key into Flutter or source control.
- Use `http://10.0.2.2:54421` for an Android Emulator and `http://127.0.0.1:54421` with `adb reverse tcp:54421 tcp:54421` for a USB device. Debug cleartext HTTP is enabled only in the Android debug manifest.
- Validate seeded Email/Password Customer and Provider accounts for the Supabase-backed flow. Demo OTP `123456` is a development Fake/Demo path only; production config without Supabase values must fail closed.
- Exercise Customer job/photo upload, Provider feed/bid, Admin local preview, bid acceptance/address isolation, lifecycle/reviews/reports/no-show, notification rows/outbox/unread state, restart/offline recovery, private Storage, RLS, and two-account concurrency. Native FCM, real SMS, cloud, Play, and payment flows are out of scope.
- Record each device model/API, connection mode, scenario result, and blocker in `docs/LOCAL_DEVICE_TEST_RESULTS.md`. A missing phone or an undersized emulator is `BLOCKED`, never a pass.
- Current evidence: core local service and automated suites pass; the `medium_phone` AVD reaches the host but cannot install the APK because of storage, and no USB device is connected, so on-device UI scenarios remain blocked.

## Later test layers

- Unit: validation, status transitions, provider eligibility, rating calculation, expiry, and contact reveal eligibility.
- Widget: auth, post-job form, job/bid/provider cards, verification, filter sheet, empty/error/loading states.
- Integration: register → post → approve → feed → bid → accept → address reveal → complete → review.
- RLS: cross-account privacy, verification files, suspended users, admin-only actions, and no service-role exposure.
- Concurrency: two devices accepting different bids leaves exactly one accepted bid and one assigned job.

## 2026-08-06 Provider Profile and category approval validation

- Profile card chevron opens the edit route and shows the authenticated provider profile.
- Profile edits persist display name, bio, phone/WhatsApp, service areas, portfolio paths, and availability.
- Existing approved categories remain approved; a newly selected category is pending and cannot expose matching jobs.
- Admin can approve/reject a pending category with a note; approval creates a provider notification and makes matching jobs visible.
- Rejected categories can be resubmitted; removed categories stop matching immediately.
- Provider availability off hides new feed jobs while assigned-job reads remain available.
- Direct provider attempts to insert an approved category are denied by RLS/trigger guards.
- `supabase/tests/run_provider_profile_local.mjs` covers 19 local RPC, RLS, feed, notification, profile, and availability checks.
## Final automated evidence (2026-08-06)

The Provider Profile change is covered by 15 static contract checks, 19 local Supabase integration checks, 2 focused Flutter tests, and the full 42-test Flutter suite. The debug APK and Admin production build both complete successfully; device UI validation remains a separate physical-device gate.

## Admin responsive layout validation (2026-08-06)

- At >=1024px, verify the sidebar, Job list, and Job detail remain visible in the desktop workspace.
- At 768–1023px, verify the sidebar remains visible, selecting a Job opens a right-side detail drawer, and closing the drawer returns to the list.
- At <768px, verify the mobile header and navigation drawer replace the stacked desktop sidebar; selecting a Job opens full-screen detail and `← Jobs` returns to the list.
- Verify mobile Job rows expose title, area, budget, status, offer count, and a touch affordance without horizontal scrolling.
- Run `node supabase/tests/validate_step9.mjs`; the current Admin contract baseline is 20 checks, followed by `npm.cmd run lint` and `npm.cmd run build`.

## Phase 1 runtime security validation (2026-08-09)

- Clean Supabase Docker reset and schema lint pass from the complete migration history and seed.
- Step 11 runner passes 19 checks covering customer/provider isolation, safe feed fields, private Storage, invalid transitions, and accept-bid concurrency.
- No-show runner passes 3 checks; expiry runner passes 3 checks; review-dimension runner passes 4 checks.
- Admin local runner passes live Auth, RLS reads, signed verification URL, moderation RPC, suspend/restore, report review, and audit-event checks.
- Provider-profile runner passes 19 checks covering pending/rejected/approved categories, approved-only feed and notification fan-out, availability, area matching, profile update, and assigned-job preservation.
- Hosted Supabase, physical-device, dual-device UI, real SMS, native FCM, and formal history secret scanner remain separate BLOCKED gates.

Phase 1 result: no confirmed local P0/P1 security defect; retain the negative tests and do not convert unavailable hosted/device checks into PASS.

## Phase 2 account/profile and product-logic checks (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| Clean migration/seed reset with provider display-name column | PASS | `supabase db reset --local` |
| Schema lint | PASS | `supabase db lint --local` |
| Provider RPC preserves customer profile name | PASS | Provider runner, identity-preservation assertions |
| Provider business name updates independently | PASS | Provider runner, provider-profile assertion |
| New-account fake Provider jobs/bids are empty | PASS | Flutter regression tests |
| Provider detail route cannot fall back to arbitrary fake job | PASS | Phase 2 static validator |
| Admin separates provider/customer names | PASS | Admin live source + production build |
| Docker integration matrix | PASS | Step 11 19; no-show 3; expiry 3; review 4; Admin; Provider Profile 22 |
| Phase 2 static contracts | PASS | `node supabase/tests/validate_phase2.mjs`, 13 checks |
| Flutter analyze/tests/debug APK | PASS | Analyze clean; 50 tests; APK built |
| Admin lint/build/audit | PASS | Lint/build clean; npm audit 0 vulnerabilities |
| Hosted/physical/dual-device validation | BLOCKED/DEFERRED | No cloud/device execution authorized in this phase |

Use the local Docker workflow as the reproducible baseline; do not promote these results to hosted or real-device claims.

## Phase 3 job scheduling and lifecycle validation (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| End time is later than start and same Malaysia calendar day | PASS | Phase 3 Docker runner, database constraints |
| UTC persistence and provider-feed schedule exposure | PASS | Phase 3 Docker runner |
| Draft/open customer edit scope and owner filtering | PASS | Fake/Supabase repository tests and static validator |
| Expiry is server-controlled and independent from scheduled end | PASS | Trigger and Phase 3 Docker runner |
| Legacy rows with time_window and null scheduled_end_at remain readable | PASS | Phase 3 Docker runner |
| Full local validation matrix | PASS | DB reset/lint, 14 Phase 3 checks, 53 Flutter tests, 69 Version 1.1 checks, Admin lint/build/audit |
| Hosted, physical-device, and dual-device validation | BLOCKED/DEFERRED | No cloud or external device execution in this phase |

## Phase 4 emulator smoke validation (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| Wiped medium_phone boots with installable storage | PASS | Android 16/API 36; approximately 5.0 GB free |
| APK uses configured local Supabase runtime | PASS | Supabase init completed; status label says local backend |
| Customer login and session restore | PASS | customer@example.test; Alex; force-stop/relaunch |
| Provider login and identity binding | PASS | provider@example.test; Ahmad Plumbing |
| Provider Mode and feed privacy | PASS | Same provider account; matching Job; Address protected |
| Complete multi-account UI lifecycle | PENDING | Bid/accept/start/complete/review/report not completed in this single-device round |
| USB and dual-device UI | BLOCKED | No authorized physical Android device connected |
| Hosted/SMS/FCM validation | DEFERRED | Out of local-only scope |

The emulator smoke pass proves local UI connectivity and identity/privacy boundaries only; it does not close the full device E2E gate.

## Phase 5 single-emulator lifecycle validation (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| Customer creates and publishes a scheduled Job | PASS | `medium_phone` UI; 10:00 AM–11:00 AM range |
| UTC schedule persistence and consistent display | PASS | REST readback plus Asia/Kuala_Lumpur emulator verification after deriving display from UTC endpoints |
| Provider feed, bid submit, and Customer bid read | PASS | RM120 bid; explicit `bids_job_id_fkey` query |
| Acceptance and address privacy boundary | PASS | Protected before accept; unlocked after accept |
| Start and complete Job | PASS | UI status and history events |
| Provider and Customer reviews | PASS | Two reciprocal 5-star rows |
| Safety report | PASS | Open report row persisted |
| Customer offer count in Job list | PASS | Rebuilt APK showed one persisted offer |
| Device photo upload | NOT RUN | Not exercised in this path |
| Physical-device and dual-device UI | BLOCKED | No USB device; emulator-only run |
| Hosted, SMS, and native FCM | DEFERRED | Local-only scope |

The single-emulator lifecycle is complete; physical-device and true UI concurrency gates remain open.

## Phase 6 schedule timezone display validation (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| UTC endpoints convert to Malaysia local display | PASS | Asia/Kuala_Lumpur emulator: 10:00Z–11:00Z rendered 6:00 PM–7:00 PM |
| Legacy rows without endpoints remain readable | PASS | Formatter falls back to `time_window` |
| Flutter timezone regression test | PASS | 53 tests passed |

## Phase 7 device photo-upload validation (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| Android Photo Picker selection | PASS | One supported image selected on `emulator-5554` |
| Preview and publish | PASS | Preview showed `1 photo(s) attached`; Job published as `open` |
| Customer photo row and private object | PASS | One `job_photos` row; Storage object HTTP 200 with Customer session |
| Provider feed and authorized object | PASS | One photo path in `public_job_feed`; Storage object HTTP 200 with Provider session |
| Physical-device and hosted Storage | BLOCKED/DEFERRED | No USB device; hosted environment not enabled |

### Phase 7.1 photo access boundary

| Check | Result | Evidence |
| --- | --- | --- |
| Unauthenticated photo object access | PASS | HTTP 400 |
| Pending Provider Feed and Storage access | PASS | 0 Feed rows; HTTP 400 object access |
| Customer and approved Provider access | PASS | HTTP 200 through authenticated sessions |

## Phase 8 Git history scan (2026-08-09)

| Check | Result | Evidence |
| --- | --- | --- |
| Sensitive file paths across Git history | PASS | 55 commits; zero `.env`, keystore, certificate, or Google Services paths |
| High-risk credential patterns across Git history | PASS | Zero private-key, service-role, Cloudflare, Firebase, common-token, or JWT matches |
| Third-party gitleaks/trufflehog execution | DEFERRED | Binaries are not installed in this environment |
