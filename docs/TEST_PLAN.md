# Test Plan

## Step 0 + Step 1 checks

- Flutter static analysis and unit/widget tests.
- Android debug build when a Flutter SDK is available.
- Admin lint and production build.
- Manual route smoke test for public, customer, provider, and admin placeholder flows.
- Search the repository for forbidden real credentials and backend URLs.

## Later test layers

- Unit: validation, status transitions, provider eligibility, rating calculation, expiry, and contact reveal eligibility.
- Widget: auth, post-job form, job/bid/provider cards, verification, filter sheet, empty/error/loading states.
- Integration: register → post → approve → feed → bid → accept → address reveal → complete → review.
- RLS: cross-account privacy, verification files, suspended users, admin-only actions, and no service-role exposure.
- Concurrency: two devices accepting different bids leaves exactly one accepted bid and one assigned job.

