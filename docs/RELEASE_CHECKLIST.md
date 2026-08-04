# Release Checklist

## Step 0 + Step 1

- [x] Flutter analyze passes (Flutter 3.44.8).
- [x] Flutter tests pass (10 tests).
- [x] Android debug build passes (`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`).
- [x] Admin lint passes.
- [x] Admin production build passes.
- [x] No Supabase/Firebase credentials committed.
- [x] No hosted migration or real bucket applied.
- [x] Public-feed privacy rules remain documented.
- [x] Project status and changelog updated.
- [x] Step 1 commit recorded with rollback point.

## Step 2 database foundation

- [ ] Migration applies to a clean Supabase local instance.
- [ ] Seed applies after migration.
- [ ] RLS privacy scenarios pass.
- [ ] Storage private-bucket scenarios pass.
- [ ] Concurrent `accept_bid` scenario passes.
- [ ] Step 2 commit and rollback point recorded.

## Step 3 authentication and profiles

- [x] Flutter Auth unit/widget tests pass.
- [ ] Runtime Supabase defines are supplied only through local/CI secrets.
- [ ] Register/login/session restore works against `ofrivo-dev`.
- [ ] Profile RLS tests pass.
- [ ] Suspended account and Provider Mode guards pass.

## Step 4 customer job creation

- [x] Job form validation tests pass.
- [ ] Draft save and publish work in local demo mode.
- [ ] Supabase insert, private job-photo upload, and draft-to-open transition pass against an isolated project.
- [ ] My Jobs and Job Detail show only the authenticated customer's jobs.
- [ ] Cancellation uses `cancel_job` and rejects non-cancellable states.
- [x] No service-role key or hosted Supabase values committed.

## Step 5 provider application

- [x] Provider application validation tests pass.
- [ ] Categories and areas persist only for the authenticated provider.
- [ ] Identity evidence and work photos upload to the private verification bucket.
- [ ] `submit_provider_application` transitions the provider to pending without allowing client-side approval.
- [ ] Pending, approved, rejected, and suspended UI states render with the correct next action.
- [ ] Supabase RLS and Storage scenarios pass against an isolated local project.
- [x] No service-role key or hosted Supabase values committed.

## Step 6 provider job feed and bids

- [x] Approved-provider feed loads only open jobs from the safe public view.
- [x] Category, area, service date, budget, urgent, no-bid, and sort filters pass fake-data tests.
- [x] Job detail hides full address, phone, WhatsApp, and exact GPS until acceptance.
- [x] Provider can submit, edit, and withdraw a pending bid.
- [x] My Bids shows only the authenticated provider's bid records.
- [x] Step 6 static migration/mobile contract validation passes.
- [x] No service-role key or hosted Supabase values committed.

## Before any beta

- [ ] RLS and storage permission tests pass.
- [ ] Transactional bid acceptance concurrency test passes.
- [ ] Privacy Policy, Terms, provider agreement, retention, deletion, and appeals flows exist.
- [ ] Test accounts and rollback build are documented.
