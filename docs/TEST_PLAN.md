# Test Plan

## Step 0 + Step 1 checks

- Flutter static analysis and unit/widget tests.
- Android debug build with the prepared Flutter SDK.
- Admin lint and production build.
- Manual route smoke test for public, customer, provider, and admin placeholder flows.
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

## Later test layers

- Unit: validation, status transitions, provider eligibility, rating calculation, expiry, and contact reveal eligibility.
- Widget: auth, post-job form, job/bid/provider cards, verification, filter sheet, empty/error/loading states.
- Integration: register → post → approve → feed → bid → accept → address reveal → complete → review.
- RLS: cross-account privacy, verification files, suspended users, admin-only actions, and no service-role exposure.
- Concurrency: two devices accepting different bids leaves exactly one accepted bid and one assigned job.
