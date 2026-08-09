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
