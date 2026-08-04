# Release Checklist

## Step 0 + Step 1

- [ ] Flutter analyze passes (blocked: Flutter SDK unavailable in current environment).
- [ ] Flutter tests pass (blocked: Flutter SDK unavailable in current environment).
- [ ] Android debug build passes (blocked: Flutter SDK unavailable in current environment).
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

- [ ] Flutter Auth unit/widget tests pass once the SDK is available.
- [ ] Runtime Supabase defines are supplied only through local/CI secrets.
- [ ] Register/login/session restore works against `ofrivo-dev`.
- [ ] Profile RLS tests pass.
- [ ] Suspended account and Provider Mode guards pass.

## Step 4 customer job creation

- [ ] Job form validation tests pass once the Flutter SDK is available.
- [ ] Draft save and publish work in local demo mode.
- [ ] Supabase insert, private job-photo upload, and draft-to-open transition pass against an isolated project.
- [ ] My Jobs and Job Detail show only the authenticated customer's jobs.
- [ ] Cancellation uses `cancel_job` and rejects non-cancellable states.
- [x] No service-role key or hosted Supabase values committed.

## Before any beta

- [ ] RLS and storage permission tests pass.
- [ ] Transactional bid acceptance concurrency test passes.
- [ ] Privacy Policy, Terms, provider agreement, retention, deletion, and appeals flows exist.
- [ ] Test accounts and rollback build are documented.
