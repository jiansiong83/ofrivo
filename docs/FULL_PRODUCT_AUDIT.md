# Ofrivo Full Product Audit

## Audit baseline

- Audit date: 2026-08-09 (Asia/Kuala_Lumpur)
- Repository: jiansiong83/ofrivo
- Branch: master
- HEAD: 9aadff4c2fc433553bd6803a47ed015cad7afb82 (fix: fail closed for hosted mobile builds)
- Previous rollback point: b02d694 (fix: scope customer data by auth user)
- Remote: https://github.com/jiansiong83/ofrivo.git
- GitHub visibility: Public (not changed by this audit)
- Scope: Product Logic, Security, Privacy, UX, Data Isolation, lifecycle, Admin, reliability, and validation evidence.

This is the Phase 0 evidence baseline from the attached full-audit plan. Static/source evidence is separated from runtime evidence. A check is not marked PASS when Docker, hosted infrastructure, or a physical device was unavailable.

## Executive result

**No confirmed P0 defect was found in static review. The project is not yet release-ready.**

- Source contains provider-category, current-user, private-storage, Admin-RPC, and hosted fail-closed hardening.
- Flutter and Admin static/build checks pass.
- Supabase SQL/RLS/Storage integration could not run because the Docker daemon is unavailable.
- Hosted Supabase behavior, real Android UI, dual-device concurrency, SMS, and FCM were not verified.
- Formal Git-history secret scanning is blocked because gitleaks and trufflehog are not installed.

> Local source and application automation are substantially validated; runtime security, hosted behavior, and real-device E2E remain open gates.

No business feature was changed in Phase 0.

## Evidence collected

### Repository and source review

- All 12 SQL migrations were read, including provider-category approval and scheduled-time-range migrations.
- Flutter repositories/controllers and apps/admin/lib/admin-repository.ts were reviewed for current-user binding and server access.
- README.md, PROJECT_STATUS.md, SECURITY.md, TEST_PLAN.md, RELEASE_CHECKLIST.md, and CHANGELOG.md were reviewed.
- Tracked-file checks found no .env, keystore, google-services.json, .p12, .pem, or private-key filename.
- Manual review found no committed service-role value, Cloudflare token, Firebase service-account value, or database password. This is not a history scan.

### Validation matrix

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| flutter analyze | PASS | No issues found. |
| flutter test | PASS | 48 tests passed. |
| node scripts/validate_version11.mjs | PASS | 69 contract checks passed. |
| node supabase/tests/validate_provider_profile.mjs | PASS | 15 provider-profile checks passed. |
| Flutter debug APK | PASS | APK output built successfully. |
| Admin npm run lint | PASS | Current Admin source passes lint. |
| Admin production build | PASS | Next.js 16.3.0 build completed. |
| Admin npm audit --audit-level=high | PASS | 0 vulnerabilities reported. |
| supabase db reset | BLOCKED | Docker engine unavailable; docker info cannot connect to dockerDesktopLinuxEngine. |
| supabase db lint | BLOCKED | Requires the unavailable local database. |
| Docker integration runners | BLOCKED | Six runners exist but cannot execute without containers. |
| gitleaks / trufflehog history scan | BLOCKED | Neither scanner is installed. |
| USB physical-device E2E | BLOCKED | No connected/authorized USB device. |
| Dual-device UI concurrency | BLOCKED | Requires emulator/physical-device runtime. |
| Hosted Supabase migration/RLS/Storage | BLOCKED | No hosted deployment/test credentials used in this audit. |
| Real SMS / FCM delivery | BLOCKED | Explicitly outside local-only scope. |

## Confirmed controls

### C-001 — Provider category approval

Status: SOURCE-CONFIRMED; RUNTIME BLOCKED.

supabase/migrations/20260806000100_provider_profile_category_approval.sql redefines public_job_feed, can_read_job, and notify_new_job_event. Matching branches require provider_categories.status = 'approved' and an approved, available provider. Earlier broader definitions are superseded on a clean reset. The provider validator covers pending/rejected/approved cases.

Acceptance remains pending: run a clean reset and provider-profile runner, then repeat against labelled staging before treating it as production-closed.

### C-002 — Customer isolation

Status: SOURCE-CONFIRMED; RUNTIME BLOCKED.

Customer job reads/writes use customer_id; received-bid reads use an inner jobs(customer_id) relation; notifications use the current user ID. Database policies and can_read_job provide the server boundary. This work is present in b02d694 and later commits.

### C-003 — Provider isolation

Status: SOURCE-CONFIRMED; RUNTIME BLOCKED.

Provider profile, verification, categories, areas, photos, bids, and assigned-job queries use the current provider ID. Feed reads use public_job_feed rather than private job columns.

### C-004 — Hosted fail-closed mobile configuration

Status: SOURCE-CONFIRMED.

app_config.dart throws for APP_ENV=staging or production when SUPABASE_URL or SUPABASE_ANON_KEY is missing. Development may still use the demo adapter. scripts/local-dev.ps1 rejects partial hosted overrides and forwards APP_ENV.

### C-005 — Admin RPC authorization

Status: SOURCE-CONFIRMED; RUNTIME BLOCKED.

Admin RPCs use security definer, fixed search_path, and internal auth.uid()/is_admin checks. Admin uses the anon/publishable key path and does not bundle a service-role key.

### C-006 — Private evidence boundary

Status: SOURCE-CONFIRMED; RUNTIME BLOCKED.

Verification and report evidence buckets are private and sensitive access uses signed URLs. Portfolio material is separated from verification evidence. Object-level behavior still needs integration tests.

## Findings by priority

### P0 — No confirmed source-level P0; runtime closure required

Static review found no direct secret value or confirmed cross-account read. This does not prove a live database is safe. Before external testers, prove: customer/provider isolation; approved-only feed and notifications; non-admin rejection of Admin RPCs; no unaccepted-provider address/contact access; and no service-role/hosted secret in artifacts.

### P1 — Security and release gates

#### P1-001 — RLS/Storage/integration unverified

Docker is unavailable, so db reset, db lint, and all six runners are blocked. Static SQL review cannot close policy interaction, triggers, Storage, or transaction behavior. Next acceptance: start Docker, reset from migrations/seed, run runners, add cross-account negatives, and record Phase 1 output.

#### P1-002 — Hosted Supabase unverified

No hosted migration, RLS, Storage, Auth configuration, or rollback was exercised. Next acceptance: use labelled staging, apply migrations in order, repeat the negative security matrix, and keep keys out of Git.

#### P1-003 — Formal history secret scan unavailable

The repository is Public and scanners are not installed. Manual checks found no actual secret value, but deleted historical files and encoded values are unverified. Next acceptance: run a history-aware scanner, review/rotate findings, and record the tool version/output.

#### P1-004 — Demo/hosted separation needs an operational release gate

Development intentionally falls back to fake data; staging/production fail closed after 9aadff4. A tester can still mistake a development APK for a cloud build. Next acceptance: label environment in UI/build metadata, require explicit staging configuration, and exclude demo fallback from release artifacts.

### P2 — Correctness, product, and validation gaps

#### P2-001 — Control documents are stale relative to HEAD

PROJECT_STATUS.md still describes the older 61e112a/39-test baseline and old emulator blocker; RELEASE_CHECKLIST.md has old test counts. Update the six control documents at the end of each phase with exact commit, test count, blockers, and rollback.

#### P2-002 — Admin live-data path needs runtime re-validation

Admin source reads live tables and uses moderation RPCs, but Docker prevents the local database/browser smoke path. Do not equate this with the earlier fake-data preview until rerun.

#### P2-003 — Signed URL ownership/expiry is source-only

Private buckets and signed URL paths exist, but runtime proof that another user's path cannot be substituted or retained after expiry is missing. Add this to Phase 1 Storage tests.

#### P2-004 — Realtime/event boundaries are unverified

Notification rows, outbox writes, and unread state exist. Realtime filtering, duplicate delivery, reconnect behavior, and payload privacy remain unverified.

#### P2-005 — Remaining product edge cases need explicit phase audits

Verify account/profile binding, empty states for new users, job time-range and timezone rules, lifecycle expiry/cancel/start/complete, bid replacement/concurrency, review/report participants, notification idempotency, Admin mobile layout, pagination/refresh, and actionable retry states. These are pending audits, not claimed defects.

### P3 — Deferred or external-only

- Real SMS provider behavior and native FCM when the app is killed/backgrounded.
- Cloudflare/Vercel/domain/Play Store/iOS/payment/maps/chat/membership/referral and other frozen features.
- Long-run performance, large-list pagination, and production observability.

These must not be presented as MVP validation passes.

## Phase coverage

| Phase | Static status | Runtime status | Next evidence |
| --- | --- | --- | --- |
| 1 Security/data isolation | Latest approval and hosted fail-closed controls reviewed | BLOCKED | Docker reset, RLS/Storage negatives, staging |
| 2 Account/profile/multi-role | Repositories reviewed; full identity binding not closed | BLOCKED | Two accounts, mode/profile isolation, guards |
| 3 Jobs/lifecycle/time range | Migrations/repositories present; edge cases pending | BLOCKED | UTC/Malaysia, invalid/overnight, expiry/lifecycle |
| 4 Bids/concurrency | Transactional RPC/source present | BLOCKED | Two providers, exactly-one acceptance, privacy |
| 5 Trust/reviews/reports | Participant-derived source present | BLOCKED | Completion, duplicates, evidence boundary |
| 6 Notifications | Rows/outbox/trigger source present | BLOCKED | Idempotency, unread/read, reconnect, payload privacy |
| 7 Admin | Live repository/RPC source; lint/build pass | BLOCKED | Live browser, moderation/audit/signed URLs, responsive layouts |
| 8 MVP functions | Core paths exist; feature freeze respected | BLOCKED | Customer → Provider → Admin device journey |
| 9 Reliability/performance | Static/build evidence only | BLOCKED | Restart, network interruption, retry/recovery |
| 10 Test matrix | Automated checks recorded | PARTIAL | Complete blocked rows without converting to PASS |

## Phase 1 remediation order

1. Start Docker Desktop and verify docker info.
2. Run supabase start, supabase db reset, supabase db lint, and all six local integration runners.
3. Add/repair cross-account negatives for jobs, bids, notifications, reviews, Storage, Admin RPCs, and pending categories.
4. Re-run Flutter/Admin/static validators after changes.
5. Update the six control documents and commit Phase 1 independently.
6. After local security gates pass, apply the same migrations to labelled staging and repeat the matrix.
7. Resume device E2E. No Cloudflare/Vercel/Play Store/paid provider is required for this next step.

## Phase 0 change and rollback

- Change: this audit baseline only; no business logic, migration, policy, or dependency changed.
- Commit: docs: establish full product audit baseline.
- Rollback point: 9aadff4 before the audit-document commit.
- Revert only the documentation commit if needed; do not reset the repository destructively.

## Audit decision

Phase 0 is complete when this document is committed with exact outputs and blocked gates visibly blocked. Phase 1 starts with runtime security/data-isolation validation, not new features.

## Phase 1 update (2026-08-09)

This section supersedes the Phase 0 local-runtime BLOCKED snapshot above. Docker Desktop was started and the local runtime matrix was executed from a clean reset.

- supabase db reset: PASS.
- supabase db lint: PASS; no schema errors.
- Step 11: PASS, 19 checks.
- No-show: PASS, 3 checks.
- Expiry: PASS, 3 checks.
- Review dimensions: PASS, 4 checks.
- Admin live Auth/RLS/Storage/RPC/audit runner: PASS.
- Provider profile/category/availability runner: PASS, 19 checks.
- Runtime checks confirmed customer/provider isolation, approved-only category feed and notification fan-out, private Storage ownership, Admin authorization, invalid transition rejection, and one-winner bid acceptance.

Local P1-001 is closed for the Docker environment and C-001, C-002, C-005, and C-006 now have local runtime evidence. Hosted Supabase, formal Git-history secret scanning, physical-device UI, dual-device UI, SMS, and FCM remain blocked. No migration or business-code fix was required.

The control-document drift finding is addressed by the Phase 1 updates in PROJECT_STATUS.md, TEST_PLAN.md, RELEASE_CHECKLIST.md, SECURITY.md, and CHANGELOG.md. The next phase is account/profile and product-logic edge-case validation; this local PASS must not be promoted to hosted or real-device PASS.

## Phase 2 update (2026-08-09): account/profile and product-logic audit

This section supersedes the earlier Phase 2 “blocked” snapshot for the local Docker environment. The audit found and fixed a real identity-binding defect: provider business names were stored in `profiles.display_name`, so editing Provider Profile could change the Customer identity.

### Findings fixed

- Added `provider_profiles.display_name` with a backfill and provider-directory view update.
- Renamed/revoked the legacy provider application/update RPCs and added authenticated wrappers that preserve `profiles.display_name`.
- Updated mobile profile parsing, Supabase hydration, Provider application loading, fake Provider account mapping, and Provider detail routing.
- Updated Admin live mapping so provider business names and customer names are rendered in their correct contexts.
- Added regression coverage for new-account fake-data isolation and provider/customer identity separation.

### Evidence

- Clean `supabase db reset --local` and `supabase db lint --local`: PASS.
- Local integration: Step 11 19, no-show 3, expiry 3, review 4, Admin, and Provider Profile 22 checks: PASS.
- `node supabase/tests/validate_phase2.mjs`: PASS, 13 checks.
- `node scripts/validate_version11.mjs`: PASS, 69 checks; Provider Profile validator: PASS, 15 checks.
- Flutter analyze: PASS; Flutter tests: PASS, 50 tests; debug APK: PASS.
- Admin lint/build: PASS; npm audit reports 0 vulnerabilities.

### Remaining gates

Hosted Supabase, USB physical-device UI, dual-device UI, real SMS, native FCM, and formal Git-history secret scanning remain unverified/deferred. Local PASS must not be presented as hosted or real-device PASS.

### Phase 2 decision

The local account/profile binding gate is PASS. The next authorized step is commit/review of this phase, followed by device or hosted validation only when explicitly requested.

## Phase 3 update (2026-08-09): job scheduling and lifecycle audit

The local product-logic audit is complete for Job creation, scheduling, editing, expiry, and state transitions. The confirmed gaps were hardened without adding a new marketplace feature.

### Findings fixed

- Customer Job editing now uses the authenticated owner and is limited to draft/open states.
- The mobile flow exposes a dedicated edit route and preserves publish-versus-update behavior.
- Database-side protection prevents customer expiry tampering and open-to-draft rollback.
- New schedule ranges require a later end time on the same Malaysia calendar day and persist as UTC.
- Legacy Jobs with only time_window remain readable while new writes use scheduled_end_at.

### Evidence

- Clean supabase db reset --local and supabase db lint --local: PASS.
- Phase 3 Docker runner: PASS, 14 checks.
- Static Phase 3 validator: PASS, 11 checks.
- Flutter analyze/tests/debug APK: PASS; 53 tests.
- Version 1.1 validator: PASS, 69 checks.
- Admin lint/build and npm audit --audit-level=high: PASS, 0 vulnerabilities.

### Remaining gates

Hosted Supabase, USB physical-device UI, dual-device UI, real SMS, native FCM, and formal Git-history secret scanning remain unverified/deferred. Local PASS must not be presented as hosted or real-device PASS.

## Phase 4 update (2026-08-09): emulator smoke and environment separation

The authorized Android Emulator was wiped and used for a local Supabase-backed smoke run. This closes a subset of the device gate without overstating the unavailable full lifecycle.

- The medium_phone AVD booted with approximately 5.0 GB free storage after the wipe.
- A configured debug APK installed through the documented emulator endpoint and logged successful Supabase initialization.
- Customer login/session restore and Provider login/mode/profile/feed flows passed with distinct authenticated identities.
- Provider pre-acceptance detail kept full address, phone, WhatsApp, and GPS hidden.
- The auth screen environment label was corrected after observing a misleading Demo-only message in a configured build.

### Evidence

- Device log: docs/LOCAL_DEVICE_TEST_RESULTS.md, Phase 4 emulator evidence.
- Flutter analyze: PASS; Flutter tests: PASS, 53 tests.
- Phase 3 static validator: PASS, 11 checks.
- Debug APK install and Supabase initialization: PASS on emulator-5554.
- Full lifecycle UI, USB/two-device UI, hosted Supabase, SMS, FCM, and cloud deployment remain open gates.

### Decision

Local emulator smoke is PASS for connectivity, session restoration, identity binding, mode switching, feed matching, and pre-acceptance privacy. It is not a complete multi-device E2E or hosted release approval.

## Phase 5 update (2026-08-10): local runtime recovery and Provider/Admin revalidation

This section supersedes the original Docker-unavailable snapshot for the local environment. It does not close hosted, physical-device, or native-delivery gates.

- Docker Desktop and Supabase were safely recovered with CLI stop/start; the existing Docker volume was preserved and no database reset or volume deletion was performed in this round.
- Local REST, Auth, Studio, and Mailpit returned HTTP 200 with 12 Supabase containers running.
- The complete local integration sequence passed: Step 11 (19), no-show (3), expiry (3), review (4), Admin live integration (6 audit events), Provider Profile (22), and Phase 3 scheduling/lifecycle (14).
- A configured local-Supabase APK was installed on `emulator-5554`; exact `provider@example.test` Auth login loaded `Ahmad Plumbing` and an account-owned Customer empty state.
- Same-session mode switching entered Provider Mode without identity substitution. The feed returned two matching Plumbing jobs and excluded the Electrical job because Electrical was not selected/approved for this Provider.
- Pre-acceptance Job detail showed `Address protected` and `Submit a bid`; full address, phone, WhatsApp, and GPS were absent from the UI tree.
- Provider Profile showed persisted business name, categories, availability, and Approved verification; the profile card opened the real edit route.
- Force-stop/relaunch restored the Auth session and intentionally returned the UI to Customer mode.
- Local Admin integration re-read real provider verification, jobs, bids, reports, audit rows, signed URL behavior, and moderation RPCs; all runner checks passed. `http://localhost:3000/` also returned HTTP 200 while the dev server was running.
- Interactive Admin browser click-through was not claimed: the Codex Browser runtime failed to start in the current Windows sandbox. This is an environment/tooling limitation, not a product PASS or FAIL.

### Updated decision

Local automated validation, local Supabase runtime, and single-emulator Customer/Provider UI evidence are PASS for the covered scenarios. The current documentation baseline is commit `7c958ab`; this audit update is documentation-only. No cloud deployment, paid service, real SMS, or native FCM was used.

### Remaining gates

- USB physical-device UI and true two-device UI concurrency remain BLOCKED.
- Interactive Admin browser moderation smoke remains BLOCKED until browser control is available; live Admin database/RPC integration is PASS.
- Hosted Supabase/Auth/RLS/Storage, staging secrets, real SMS, and native FCM remain DEFERRED.
- Third-party gitleaks/trufflehog history scanning remains unavailable; Git-native history scan is PASS with zero sensitive-path/pattern hits.
- Cloudflare, Vercel, Play Store, domain, payment, maps, chat, membership, and other frozen features remain out of scope.
