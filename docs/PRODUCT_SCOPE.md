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

## Step 4 delivered here

- Customer job form with category, area, title, description, full address, contact phone, WhatsApp, budget, time window, urgency, and photo selection.
- Draft save, preview, publish, My Jobs, Job Detail, and cancellation flow.
- Supabase repository for jobs and private job-photo Storage uploads, with a fake repository for demo mode.
- Job controller loading/error states and local tests for draft validation and lifecycle actions.

## Step 5 delivered here

- Provider information form with business/display name and bio.
- Service category and area selection using the seeded marketplace options.
- Private identity evidence upload (ID front/back, selfie, optional SSM/certificates) and up-to-six work photos.
- Pending, approved, rejected, and suspended verification status UI with admin-note and resubmission states.
- Supabase `submit_provider_application` RPC, private verification Storage uploads, provider portfolio photo table, and a fake repository for demo mode.

## Explicitly deferred

Provider feed/bids and push-ready notification inbox/token contracts are implemented; native FCM delivery, payments, escrow, wallet, chat, live GPS, auto-dispatch, maps, AI pricing, membership, referrals, iOS production release, and multi-city launch are later steps.

## Launch service categories

Plumbing / Toilet, Electrical / Lighting / Fan, Air Conditioning, Moving / Delivery, Cleaning, and Handyman.

## Safety boundaries

The first release does not open locksmithing, childcare, medical care, personal-driver work, financial services, lending, high-value renovation, high-risk engineering, or regulated specialist work.
