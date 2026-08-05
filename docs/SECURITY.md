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

## Step 9 Admin Web controls

- The browser preview uses fake data only and does not embed a service-role key or hosted Supabase secret.
- Production admin routes must require Supabase Auth admin claims and server-side RLS/policy checks for every provider, user, job, bid, report, taxonomy, and settings mutation.
- Verification evidence and private job addresses are admin-only fields; serve evidence through short-lived signed URLs and never expose storage paths as public URLs.
- Provider, account, and report actions must write an actor, target, action, and timestamp to the audit log in the same server-authorized operation.

## Step 10 Push Notification controls

- Device tokens are registered through authenticated RPCs, validated for platform and length, and can only be removed by their owning user.
- Notification fan-out is server-side; clients can read/update only their own inbox rows through RLS and cannot create verification, bid, or expiry notifications directly.
- `notifications` is the durable outbox for a later FCM worker. FCM credentials, scheduled-job credentials, and any provider access token remain server-only secrets.
- Runtime `PUSH_DEVICE_TOKEN` is optional demo/bridge input and is never committed; an absent token leaves the app in inbox-only mode without failing sign-in.

## Step 11 Security and testing controls

- RLS, private Storage, multiple-account, invalid-transition, and concurrent-acceptance scenarios pass in the isolated local Docker runtime through `run_step11_local.mjs`; hosted Supabase execution remains a separate gate.
- Job-scope security-definer helpers prevent policy recursion, and the server-only `service_role` receives explicit table grants without being exposed to mobile/admin clients.
- Image inputs are bounded by extension, file signature, size, count, duplicate-path, and existence checks before upload; server-side Storage policies remain authoritative.
- Error and offline states expose retry/recovery without revealing backend details, and uncaught Flutter/async failures are captured only in an in-memory diagnostic sink.
- The security validator rejects missing RLS/Storage/concurrency contracts and checks that mobile source contains no service-role credential.

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

## Version 1.1 Phone OTP controls

- Phone numbers are normalized to an E.164-style `+` value before either demo or Supabase Auth calls; malformed values are rejected client-side.
- The mobile client uses only the public Supabase Auth API (`signInWithOtp` and `verifyOTP`); no SMS provider credential or service-role key is bundled.
- A phone-only session seeds a profile from the verified phone identity only when no existing profile row is present; existing profile data is preserved.
- Local demo mode uses an explicit deterministic code for offline testing and never contacts a backend; real SMS delivery requires Supabase provider configuration.
- Language preference stores only `en`, `ms`, or `zh` in local app preferences; it never includes account, phone, token, or job data.

## Version 1.1 Provider Portfolio controls

- Public portfolio work photos use the separate `provider-portfolio` bucket; identity evidence, certificates, and other verification files remain in the private `provider-verifications` bucket.
- Portfolio uploads are folder-scoped to the authenticated provider (or an admin); public reads expose only approved active-provider photo paths through `public_provider_portfolio`.
- The portfolio view does not include phone, WhatsApp, address, verification evidence, or account-status fields beyond the approved/active filter.

## Version 1.1 No-show controls

- `mark_no_show` accepts only assigned/in-progress jobs and derives the reported user from the accepted bid; a caller cannot submit an arbitrary target account.
- Duplicate markers for the same reported participant are rejected under the locked job transaction, while the event metadata reason is bounded to 500 characters.
- No-show events remain behind the existing participant/admin `job_events` RLS policy, and notifications are inserted only for the reported user.

## Version 1.1 Job auto-expire controls

- Publish-time expiry defaults are assigned by a database trigger; the service worker does not trust a browser-supplied status transition.
- `expire_open_jobs` is bounded and service-role-only, locks due open rows with `SKIP LOCKED`, and changes only `open` jobs; assigned/in-progress work is unaffected.
- Pending bids, job events, and customer notifications are written in the same security-definer transaction, preventing half-expired jobs.

## Version 1.1 Review dimension controls

- Review inserts still require the authenticated reviewer, a completed job, and the customer/accepted-provider pair; the existing unique `(job_id, reviewer_id)` rule prevents duplicates.
- Punctuality, quality, and communication scores are required for new rows and constrained to 1–5 by the database; legacy reviews are backfilled to a safe neutral default during migration.
- No client update path is granted for reviews, so submitted scores and comments cannot be rewritten by a participant.

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
