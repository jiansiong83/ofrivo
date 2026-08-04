# Test Plan

## Step 0 + Step 1 checks

- Flutter static analysis and unit/widget tests.
- Android debug build when a Flutter SDK is available.
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
- Flutter unit/widget tests and Android build remain environment-blocked until a Flutter SDK is available.

## Later test layers

- Unit: validation, status transitions, provider eligibility, rating calculation, expiry, and contact reveal eligibility.
- Widget: auth, post-job form, job/bid/provider cards, verification, filter sheet, empty/error/loading states.
- Integration: register → post → approve → feed → bid → accept → address reveal → complete → review.
- RLS: cross-account privacy, verification files, suspended users, admin-only actions, and no service-role exposure.
- Concurrency: two devices accepting different bids leaves exactly one accepted bid and one assigned job.
