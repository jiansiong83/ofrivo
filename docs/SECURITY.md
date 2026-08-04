# Security Baseline

Step 2 adds the local SQL implementation of these controls. It still does not connect the mobile or admin apps to a hosted backend.

## Required controls

- Enable RLS on every user-data table.
- Keep provider-verification and report-evidence buckets private.
- Use short-lived signed URLs for sensitive files.
- Never put `service_role` in Flutter. The app may only receive `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Reveal full address/contact data only to the customer, admin, or accepted provider.
- Require `verification_status = approved` before bidding.
- Enforce suspended-account checks server-side.
- Use transactional RPCs for `accept_bid`, `start_job`, `complete_job`, and `cancel_job`.
- Record transitions in `job_events`.
- Limit image type, size, count, and dimensions; remove EXIF/GPS metadata where possible.

## Implemented in Step 2 SQL

- All planned user-data tables enable RLS.
- `public_job_feed` exposes only public job fields to an approved provider.
- Direct `jobs` reads are limited to the customer, admin, or accepted provider.
- Partial unique indexes prevent multiple active bids per provider/job and multiple accepted bids per job.
- Storage policies keep verification and report evidence private.
- `accept_bid` locks the job row before accepting one bid and rejecting the rest.
- RPC functions write `job_events` and notifications inside the same transaction.

## Environment contract

Mobile: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `APP_ENV=development` (not used in this round).

Admin browser: public Supabase values only. A service-role key, if later needed, belongs exclusively in a server environment and is never exposed to the client bundle.

Edge functions: FCM service credentials only in managed server secrets.
