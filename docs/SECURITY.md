# Security Baseline

Step 2 adds the local SQL implementation of these controls. The mobile app can use the same policies when runtime Supabase values are supplied; no hosted project values are committed.

## Required controls

- Enable RLS on every user-data table.
- Keep provider-verification and report-evidence buckets private.
- Use short-lived signed URLs for sensitive files.
- Never put `service_role` in Flutter. The app may only receive `SUPABASE_URL` and `SUPABASE_ANON_KEY` through runtime configuration.
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
- The customer UI invokes `accept_bid` rather than issuing independent bid/job updates; fake mode mirrors the same all-or-nothing transition for local testing.
- Provider address/contact reads use the accepted-provider job path; the provider feed and bid cards only receive public job fields.
- Start/complete/cancel actions call transaction RPCs; the client never performs a sequence of status updates.
- Review and report inserts derive the opposite participant from the accepted bid in Supabase mode, while database triggers enforce completed-job/participant rules.

## Environment contract

Mobile: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `APP_ENV=development`, supplied with `--dart-define` or a CI secret. No values are committed.

Admin browser: public Supabase values only. A service-role key, if later needed, belongs exclusively in a server environment and is never exposed to the client bundle.

Edge functions: FCM service credentials only in managed server secrets.

## Step 3 Auth controls

- Supabase Auth is initialized only when both runtime values are present.
- The mobile app never falls back to a service-role key.
- A first authenticated session upserts its own `profiles` row; RLS remains the authority.
- Suspended profiles are held at the account-suspended state.
- Provider mode is guarded by the profile's approved verification status.

## Step 4 Customer Job controls

- Job creation always uses the authenticated customer ID; the app never accepts a caller-supplied owner ID.
- Full address and contact fields are collected for the job owner but are not sent through the public feed view.
- Provider feed photos remain in the private `job-photos` bucket; the app only requests short-lived signed URLs for jobs already authorized by the feed view.
- Job photos use the private `job-photos` bucket and a job-scoped path; Storage RLS checks the job participant.
- The app limits photo selection to five items and reports missing-file/upload failures instead of silently publishing.
- Customer cancellation calls the server-side `cancel_job` RPC, which enforces the allowed status and actor checks.

## Step 5 Provider Application controls

- Direct client inserts are restricted to `not_applied` provider profiles and `pending` verification rows.
- Provider verification status, approval timestamps, suspension timestamps, and admin review fields remain server-controlled.
- `submit_provider_application` validates category/area IDs, evidence ownership paths, evidence counts, and active-account status in one transaction.
- Identity evidence and work photos use the private `provider-verifications` bucket; paths are scoped to the authenticated provider and are never public URLs.
