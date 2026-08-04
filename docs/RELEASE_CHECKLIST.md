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

## Before any beta

- [ ] RLS and storage permission tests pass.
- [ ] Transactional bid acceptance concurrency test passes.
- [ ] Privacy Policy, Terms, provider agreement, retention, deletion, and appeals flows exist.
- [ ] Test accounts and rollback build are documented.
