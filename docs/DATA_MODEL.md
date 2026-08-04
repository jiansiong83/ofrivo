# Data Model Draft

The Step 2 migration in `supabase/migrations/20260804000100_step2_foundation.sql` implements this contract locally. Step 4's mobile repository consumes the jobs and job_photos tables when runtime Supabase values are supplied. The migration must still be reviewed/applied through the Supabase CLI before any cloud environment is used.

## Planned entities

`profiles`, `provider_profiles`, `service_categories`, `areas`, `provider_categories`, `provider_areas`, `provider_verifications`, `provider_work_photos`, `jobs`, `job_photos`, `bids`, `reviews`, `reports`, `notifications`, `device_tokens`, and `job_events`.

## Core rules

- `profiles.id` will reference `auth.users(id)`.
- Jobs have `draft → open → assigned → in_progress → completed` plus cancel/expire paths.
- Provider verification is `not_applied | pending | approved | rejected | suspended`.
- Bids are `pending | accepted | rejected | withdrawn | expired`.
- Budget and bid amounts are positive; ratings are 1–5.
- One provider has at most one active bid per job; each user reviews the other party once per job.
- `accepted_bid_id` must belong to the same job.
- `job_events` records important transitions.
- `public_job_feed` and `public_provider_directory` are safe read views; they do not expose full address/contact fields.
- Step 6 appends category/area labels and private Storage paths to `public_job_feed`; the mobile repository exchanges authorized job-photo paths for short-lived signed URLs.
- `accept_bid`, `start_job`, `complete_job`, and `cancel_job` are `SECURITY DEFINER` transaction functions with explicit actor checks.
- `submit_provider_application` is a `SECURITY DEFINER` transaction function that owns the pending transition and rewrites the provider's category/area selections.
- `accept_bid` locks the job row, accepts one pending bid, rejects the other pending bids, writes `accepted_bid_id`, and creates job-event/notification rows before returning the assigned state.

## Privacy shape

`public_location_text` is feed-safe. `full_address`, phone, WhatsApp, and precise location are protected fields and are not part of the public feed response.

The provider assigned-job adapter queries accepted bids first, then reads the full job row; public feed mapping never includes `full_address`, phone, or WhatsApp.

## Local fixtures

`supabase/seed.sql` creates Customer, two approved providers, one pending provider, an Admin fixture, Johor Bahru areas, six categories, open jobs, pending bids, and an assigned job. Fixture credentials are local-only and must never be reused in a hosted environment.
