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
- Flutter validation remains blocked because the SDK is unavailable in the environment.
