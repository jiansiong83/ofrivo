# Changelog

## Unreleased — Step 0 + Step 1

- Added Ofrivo repository layout and local development guidance.
- Added product, screen map, UI, data, security, test, and release contracts.
- Added Flutter fake-data mobile shell and reusable design-system widgets.
- Added Next.js admin layout placeholder.
- Deferred all backend and later-stage product functionality by design.
- Admin lint and production build pass with Next.js 16.3.0.
- Flutter validation is recorded as blocked because the SDK is unavailable in the environment.

## Step 2 — Supabase foundation

- Added the local schema migration with enum-like status types, foreign keys, constraints, indexes, updated-at triggers, safe public views, and audit events.
- Added private Storage bucket definitions and object policies.
- Added RLS policies for profiles, providers, jobs, bids, reviews, reports, notifications, tokens, and events.
- Added transactional `accept_bid`, `start_job`, `complete_job`, and `cancel_job` RPCs.
- Added local-only seed fixtures and SQL security/concurrency test notes.

## Step 3 — Authentication and profiles

- Added runtime Supabase bootstrap using `SUPABASE_URL` and `SUPABASE_ANON_KEY` dart-defines.
- Added Email + Password repository/controller for sign-in, registration, logout, reset, and session restore.
- Added profile upsert/read, suspended-account guard, approved-provider mode guard, and local demo fallback.
- Added Auth repository/profile parsing tests.

## Step 4 — Customer Job Creation

- Added customer job draft model and required-field validation.
- Added category/area selection, private address/contact fields, urgency, service window, budget, and up-to-five photo selection.
- Added fake and Supabase job repositories, private Storage photo upload, draft/preview/publish, My Jobs, Job Detail, and cancellation flow.
- Added customer job controller loading/error states and lifecycle tests.
- Flutter validation was initially blocked until the SDK was prepared; current validation is recorded below.

## SDK preparation — Flutter Android validation

- Prepared Flutter stable 3.44.8 / Dart 3.12.2 with accepted Android SDK licenses.
- Generated the Android host project and locked the Gradle wrapper to the cached 9.1.0 binary distribution.
- Disabled Kotlin incremental compilation for the Windows cross-drive Pub-cache layout.
- `flutter analyze` passes with no issues, all 10 Flutter tests pass, and the debug APK builds successfully.

## Step 5 — Provider Application

- Added shared service category/area options and provider application draft/status models.
- Added Provider Information form, category/area selection, private ID/SSM/certificate evidence, and work-photo selection.
- Added Pending, Approved, Rejected, and Suspended verification status UI.
- Added fake and Supabase provider application repositories with private Storage upload cleanup.
- Added `provider_work_photos` and protected `submit_provider_application` migration/RPC, including server-controlled status transitions.
- Added provider application validation and fake lifecycle tests.
- Flutter validation passes with the prepared SDK; see the SDK preparation entry above.

## Step 6 — Provider Job Feed and Bid

- Added approved-provider feed models, filters, controller, fake repository, and Supabase `public_job_feed` adapter.
- Added category, area, service-date, budget, urgent, no-bids, and sort filters.
- Added safe job detail with private address/contact boundary and signed job-photo support.
- Added bid submission, pending-bid edit, pending-bid withdrawal, and provider-scoped My Bids UI.
- Added the Step 6 feed/view migration, static contract validator, and five fake lifecycle/filter tests.

## Step 7 — Transactional Accept Bid

- Added customer Received Bids and Provider Profile flows with provider-directory mapping.
- Wired customer acceptance to the existing PostgreSQL `accept_bid` RPC; the fake adapter mirrors the atomic state transition for local preview.
- Added selected-bid acceptance, automatic rejection of other pending bids, assigned-job refresh, and concurrency guard tests.
- Added accepted-provider assigned-job loading with full address/contact reveal only after authorization.
- Added notification repository/controller, unread styling, mark-read behavior, and fake/Supabase adapters.
- Added Step 7 RPC/mobile contract validation; Flutter analyze, 18 tests, and Android debug build pass.
