-- Step 11 manual security and resilience scenarios.
-- Run after the Step 2, Step 5, Step 6, Step 7, and Step 10 migrations plus
-- seed.sql in an isolated Supabase project. Each account block must run in a
-- separate authenticated session; fixture IDs are listed in README.md.

-- RLS-01: provider feed privacy and account isolation.
-- set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000102', true);
-- set_config('request.jwt.claim.role', 'authenticated', true);
-- select id, title, public_location_text, budget_amount from public.public_job_feed;
-- select full_address from public.jobs where id = '00000000-0000-0000-0000-000000000301';
-- Expected: the feed returns only safe fields; the unrelated customer address
-- returns no rows for Provider A.

-- STORAGE-01: private verification and report evidence.
-- Attempt an unauthenticated download of provider-verifications and
-- report-evidence through the Storage API; expect 401/403. Then request a
-- short-lived signed URL as the owner/admin and confirm it expires.

-- ACCOUNT-01: multiple-account boundaries.
-- Session A (customer) reads own jobs and notifications.
-- Session B (provider) reads only the safe feed, own bids, and accepted jobs.
-- Session C (pending provider) attempts the provider feed and a pending bid.
-- Expected: A/B data never crosses accounts and C receives an eligibility/RLS
-- error without a provider address or verification file.

-- CONCURRENCY-01: two devices accept different bids for the same open job.
-- Run these two calls concurrently in separate customer sessions:
-- select public.accept_bid('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000401');
-- select public.accept_bid('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000402');
-- Expected: one success and one state/lock error; exactly one accepted bid
-- and one assigned job remain.

-- ERROR-01: invalid state transitions return safe, actionable errors.
-- select public.start_job('00000000-0000-0000-0000-000000000301');
-- select public.complete_job('00000000-0000-0000-0000-000000000301');
-- select public.cancel_job('00000000-0000-0000-0000-000000000304', null);
-- Expected: no partial status update or notification is written.

-- OFFLINE-01 / CRASH-01 / IMAGE-01 are automated by the Flutter tests:
-- `flutter test test/widget_smoke_test.dart test/security_smoke_test.dart
-- test/image_validation_test.dart`.
