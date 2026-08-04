# Product Scope

## Product

Ofrivo is a local-service job-bid marketplace for Johor Bahru. Every registered account can post a job. A user may apply to become a provider; only an approved provider can see the provider feed and submit a bid.

## MVP boundary

The intended MVP covers registration, profiles, customer job creation, provider verification, provider feed, bids, one-bid acceptance, job lifecycle, reviews, reports, and admin moderation. Privacy rules must hide full addresses and contact details until a bid is accepted.

## Step 0 + Step 1 delivered here

- Screen map and navigation contract.
- Low-fidelity interaction notes.
- Material 3 design system.
- Fake-data mobile prototype and admin layout placeholder.
- Repository and environment structure.

## Step 2 delivered here

- PostgreSQL schema migration for the planned entities.
- Constraints, foreign keys, indexes, Storage bucket definitions, and RLS policies.
- Safe public feed/provider views and transactional `accept_bid`, `start_job`, `complete_job`, and `cancel_job` RPCs.
- Local fake auth users and marketplace seed data in `supabase/seed.sql`.

## Step 3 delivered here

- Email + Password sign-in, registration, sign-out, password reset, and session restore adapter.
- Profile upsert/read on first authenticated session.
- Auth loading/error/offline messaging, suspended-account guard, and approved-provider mode guard.
- Runtime-only `SUPABASE_URL` / `SUPABASE_ANON_KEY` configuration with an explicit local demo fallback.

## Explicitly deferred

App-side Supabase integration, authentication wiring, FCM, payments, escrow, wallet, chat, live GPS, auto-dispatch, maps, AI pricing, membership, referrals, iOS production release, and multi-city launch are later steps.

## Launch service categories

Plumbing / Toilet, Electrical / Lighting / Fan, Air Conditioning, Moving / Delivery, Cleaning, and Handyman.

## Safety boundaries

The first release does not open locksmithing, childcare, medical care, personal-driver work, financial services, lending, high-value renovation, high-risk engineering, or regulated specialist work.
