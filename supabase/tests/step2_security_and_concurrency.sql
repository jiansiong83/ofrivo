-- Manual SQL test scenarios for an isolated Supabase local project.
-- These statements are intentionally a test draft, not a production migration.

-- Fixture identities:
-- customer: 00000000-0000-0000-0000-000000000101
-- provider A (approved): 00000000-0000-0000-0000-000000000102
-- provider B (approved): 00000000-0000-0000-0000-000000000104
-- pending provider: 00000000-0000-0000-0000-000000000103
-- admin: 00000000-0000-0000-0000-000000000199

-- Run each block in a session with a matching JWT claim.
-- select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000102', true);
-- select set_config('request.jwt.claim.role', 'authenticated', true);

-- Provider privacy: feed exposes public fields, never full_address/contact fields.
-- select id, title, public_location_text, budget_amount, bid_count from public.public_job_feed;
-- select full_address from public.jobs where id = '00000000-0000-0000-0000-000000000301'; -- must return no rows for Provider A.

-- Eligibility: pending provider must not be able to insert a pending bid.
-- set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
-- insert into public.bids (job_id, provider_id, amount, available_at, inclusions, status)
-- values ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000103', 80, now(), 'Labour', 'pending');
-- Expected: RLS/eligibility error.

-- Address reveal: accepted Provider A may read the assigned job, but not an unrelated customer's job.
-- set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000102', true);
-- select full_address, contact_phone from public.jobs where id = '00000000-0000-0000-0000-000000000303';
-- select full_address from public.jobs where id = '00000000-0000-0000-0000-000000000301'; -- must return no rows.

-- Concurrency: run the next RPC in two separate customer sessions against two
-- different pending bids for job 000...301. Exactly one call must succeed.
-- select public.accept_bid('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000401');
-- select public.accept_bid('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000402');
-- Expected: one success, one "only open jobs" or "no longer pending" error;
-- exactly one accepted bid and one assigned job remain.

-- Sensitive storage: unauthenticated reads from provider-verifications and
-- report-evidence must fail; the owner/admin signed-URL path must succeed.

