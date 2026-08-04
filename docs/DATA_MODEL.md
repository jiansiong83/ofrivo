# Data Model Draft

This is a Step 0 contract only. No SQL migration is executed in Step 1.

## Planned entities

`profiles`, `provider_profiles`, `service_categories`, `areas`, `provider_categories`, `provider_areas`, `provider_verifications`, `jobs`, `job_photos`, `bids`, `reviews`, `reports`, `notifications`, `device_tokens`, and `job_events`.

## Core rules

- `profiles.id` will reference `auth.users(id)`.
- Jobs have `draft → open → assigned → in_progress → completed` plus cancel/expire paths.
- Provider verification is `not_applied | pending | approved | rejected | suspended`.
- Bids are `pending | accepted | rejected | withdrawn | expired`.
- Budget and bid amounts are positive; ratings are 1–5.
- One provider has at most one active bid per job; each user reviews the other party once per job.
- `accepted_bid_id` must belong to the same job.
- `job_events` records important transitions.

## Privacy shape

`public_location_text` is feed-safe. `full_address`, phone, WhatsApp, and precise location are protected fields and are not part of the public feed response.

