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

- Admin login preview gates the console and sign-out returns to the login screen.
- Dashboard queue counts navigate to Pending Providers, Reports, and Audit Log.
- Provider verification actions cover approve, reject, suspend, and restore-to-approved states; private evidence is labelled as signed-preview only.
- Users covers suspend/restore; Jobs exposes private address only in the admin detail; Bids show admin-scoped offer monitoring.
- Reports cover reviewing, resolving, and dismissing; each moderation mutation appends an audit event.
- Run `node supabase/tests/validate_step9.mjs`, `npm.cmd run lint`, and `npm.cmd run build` from `apps/admin`.

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
- Changing the persisted language rebuilds the active business screen; an unknown business key returns the key safely rather than throwing or changing authorization state.
- Run the business localization widget test together with `node scripts/validate_version11.mjs`, Flutter analyze, Flutter test, and the Android debug build; the current baseline is 65 contract checks and 38 Flutter tests.

## Later test layers

- Unit: validation, status transitions, provider eligibility, rating calculation, expiry, and contact reveal eligibility.
- Widget: auth, post-job form, job/bid/provider cards, verification, filter sheet, empty/error/loading states.
- Integration: register → post → approve → feed → bid → accept → address reveal → complete → review.
- RLS: cross-account privacy, verification files, suspended users, admin-only actions, and no service-role exposure.
- Concurrency: two devices accepting different bids leaves exactly one accepted bid and one assigned job.
