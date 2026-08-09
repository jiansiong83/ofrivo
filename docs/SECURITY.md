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

- The local Admin browser uses only the public anon key, Supabase Auth, and the active `profiles.is_admin` guard; no service-role key or hosted secret is bundled.
- Users, providers, jobs, bids, reports, taxonomy, and audit rows are read through RLS; moderation mutations use security-definer RPCs that re-check `is_admin()` server-side.
- Verification evidence and private job addresses are admin-only fields; evidence is exposed only through five-minute signed URLs and never as a public Storage URL.
- Provider, account, and report actions write actor, target, action, metadata, and timestamp to `admin_audit_events` in the same RPC transaction.

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

Mobile: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `APP_ENV` are supplied with `--dart-define` or a CI secret. `development` may intentionally use the local demo adapter when values are absent; `staging` and `production` fail closed and require both Supabase values. No values are committed.

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

## Version 1.1 Business-page localization controls

- Business copy is static localization data; the persisted language preference stores only `en`, `ms`, or `zh` and carries no account, token, contact, or job data.
- Runtime secrets, phone numbers, addresses, review content, and provider evidence are never embedded in translations; an unknown key falls back safely without changing authorization.
- Notification titles are derived from typed event enums; dynamic notification bodies remain server-supplied content and never grant access or reveal protected job fields.

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

## Local Real-Device Validation controls (2026-08-05)

- Local development uses only the public anon key at runtime. `scripts/local-dev.ps1` keeps the service-role key inside the short-lived Docker runner process and never passes it to Flutter or writes it to source.
- `APP_ENV=development` is explicit for Emulator/USB debug runs. Demo OTP `123456` is available only through Fake/Demo mode; staging and production bootstrap fail closed when Supabase runtime values are absent. `scripts/local-dev.ps1` accepts `OFRIVO_APP_ENV=staging` only together with both hosted Supabase overrides.
- HTTP cleartext is enabled only in `apps/mobile/android/app/src/debug/AndroidManifest.xml` for the local `10.0.2.2`/ADB-reverse endpoints. Release/production Android manifests do not receive this exception.
- Local Docker reset/lint and the 19-check RLS/Storage/concurrency suite, plus no-show, expiry, and review runners, passed after a local stop/start recovery. Hosted services and external delivery were not touched.
- The Admin Web is now backed by local Docker Supabase for this phase; production/cloud deployment, hosted claims, and external delivery remain deferred.

## Provider Profile and category approval controls (2026-08-06)

- Category review fields are server-managed. Non-admin clients cannot insert an approved category or alter review metadata directly.
- Category submissions validate active service IDs, duplicate-free bounds, and authenticated ownership; rejected requests clear review metadata when resubmitted.
- `review_provider_category` requires an active Admin, records the reviewer/note in `provider_categories`, appends an audit event, and inserts a user-scoped notification.
- Provider Profile and availability writes are authenticated RPCs. Turning availability off affects only new feed/open-job matching; accepted/assigned job access remains intact.
- Feed matching and new-job notifications both require `provider_categories.status = 'approved'`, the provider's approved verification, a matching area, and `is_available`.
## Phase 1 runtime security evidence (2026-08-09)

- Clean Docker reset and schema lint pass.
- Cross-account job/address/notification isolation, pending-category exclusion, approved-only feed/notification matching, private Storage ownership, Admin RPC authorization, and concurrent bid acceptance pass in the local integration matrix.
- The six local runners pass: Step 11 19 checks, no-show 3, expiry 3, review 4, Admin live integration, and provider-profile/category 19.
- No migration or policy fix was required after runtime validation; the existing latest category-approval migration remains authoritative on clean reset.
- Hosted Supabase, formal Git-history secret scan, physical-device UI, native FCM, and real SMS remain unverified and are not security PASS claims.

## Phase 2 account/profile isolation controls (2026-08-09)

- Customer identity remains in `profiles.full_name/display_name`; provider business identity is isolated in `provider_profiles.display_name`.
- The public provider directory prefers the provider profile name and exposes only approved active providers.
- Legacy provider RPC implementations are renamed and revoked from browser roles; authenticated wrappers preserve the customer profile name and update only the provider name.
- Provider application hydration reads the provider profile name; Customer and Provider UI no longer share one display-name field.
- Demo Provider repositories map only known Demo account IDs to seed Provider data; new accounts receive empty fake jobs/bids.
- Provider job detail no longer searches the global fake-job list after authenticated state lookup.

- Admin maps provider records through provider business names, while customer-owned jobs and account rows use customer names.
- Local Docker integration proves identity preservation and provider-name update behavior; static validator covers the source contracts.

No hosted, physical-device, SMS, FCM, or secret-history claim is implied by this local evidence.

## Phase 3 job/lifecycle controls (2026-08-09)

- A jobs update trigger rejects customer attempts to roll an open Job back to draft or alter its server-controlled expiry.
- Service-role-only grants cover the helper functions used by trusted local integration runners; browser roles are not granted these helpers.
- Schedule checks require a real end timestamp after the start timestamp and the same Malaysia calendar day before UTC persistence.
- Customer update queries include both customer_id = auth.uid() and the draft/open status boundary; assigned and terminal Jobs cannot be edited through the mobile repository.
- Legacy time_window remains a read-only compatibility path while new writes use scheduled_at and scheduled_end_at.
- These controls have local Docker evidence only; hosted policy execution, device testing, and history-wide secret scanning remain separate gates.

## Phase 4 emulator security evidence (2026-08-09)


- A wiped Android 16/API 36 emulator connected to the local API through 10.0.2.2:54421 using a debug-only configured build.
- Customer and Provider fixture sessions were distinct; the UI rendered Alex/customer@example.test and Ahmad Plumbing/provider@example.test from their authenticated profiles.
- Provider Mode did not substitute a seed identity, and the Provider feed exposed only the matching safe Job.
- Pre-acceptance Job detail explicitly hid full address, phone, WhatsApp, and exact GPS.
- The configured-build status label now makes local backend versus Demo mode visible to testers.
- This is local emulator evidence only; hosted RLS/Storage/Auth and dual-device concurrency remain unverified.

## Phase 5 lifecycle security evidence (2026-08-09)

- The emulator verified that full address and phone remain hidden before bid acceptance and are readable only after the accepted bid transition.
- Customer and Provider bid queries now name `bids_job_id_fkey`, preventing an ambiguous embed from returning an unintended `jobs` relationship.
- Customer offer counts are derived from the RLS-scoped `bids` relation; no service-role key is present in the APK or client code.
- Reciprocal reviews and the safety report were written with the authenticated reporter/reviewer identities and verified by local REST readback.
- Hosted RLS/Storage/Auth, physical-device, and dual-device attack validation remain unverified.

## Phase 6 schedule timezone security evidence (2026-08-09)

- Displaying from the persisted UTC endpoints removes reliance on mutable legacy text and keeps Customer/Provider schedule views consistent.
- The Malaysia-time conversion is client display logic; database constraints continue to validate the UTC range and Malaysia calendar day.
- No auth, RLS, Storage, or service-role boundary was weakened by this client-only fix.

## Phase 7 photo Storage security evidence (2026-08-09)

- Customer-authenticated readback found exactly one `job_photos` row for the newly published local Job and its private Storage object returned HTTP 200.
- Provider feed readback exposed only the permitted photo path for the matching open Job; the object was readable through the authenticated Provider session, not via an unauthenticated request.
- No service-role key was placed in the APK or browser; all checks used short-lived local user sessions and the public anon key.
- Physical-device, hosted Storage, and cross-account negative tests remain separate gates.

### Phase 7 negative access boundary

- Unauthenticated access to the uploaded object returned HTTP 400; the pending Provider saw zero matching Feed rows and received HTTP 400 for the object.
- The owning Customer and approved Provider both received HTTP 200 through their authenticated sessions.

## Phase 8 Git history secret scan (2026-08-09)

- Git-native scan covered all 55 commits reachable from the repository refs.
- Sensitive path scan found zero `.env`, keystore, certificate, or `google-services.json` paths.
- Content scan found zero PEM private keys, service-role/Cloudflare/Firebase assignments, common token prefixes, or hardcoded JWTs.
- This is a repository-history evidence pass; third-party gitleaks/trufflehog binaries are not installed and remain a separate optional check.

## Phase 9 local regression security evidence (2026-08-09)

- Repeated local RLS/RPC/Storage checks passed: Provider category approval, cross-account address/notification isolation, private photo and verification objects, invalid lifecycle transitions, and one-winner bid acceptance.
- Admin live integration passed with attributable audit events; no service-role key was sent to the mobile APK or Admin browser.
- The APK was installed and launched on the local emulator after the regression build. No hosted secrets or cloud configuration were introduced.
- Physical-device, hosted-environment, and third-party scanner gates remain unverified.
