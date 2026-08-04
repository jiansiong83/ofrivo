# Release Checklist

## Step 0 + Step 1

- [ ] Flutter analyze passes (blocked: Flutter SDK unavailable in current environment).
- [ ] Flutter tests pass (blocked: Flutter SDK unavailable in current environment).
- [ ] Android debug build passes (blocked: Flutter SDK unavailable in current environment).
- [x] Admin lint passes.
- [x] Admin production build passes.
- [ ] No Supabase/Firebase credentials committed.
- [ ] No migration or real bucket created.
- [ ] Public-feed privacy rules remain documented.
- [ ] Project status and changelog updated.
- [ ] Single round commit recorded with rollback point.

## Before any beta

- [ ] RLS and storage permission tests pass.
- [ ] Transactional bid acceptance concurrency test passes.
- [ ] Privacy Policy, Terms, provider agreement, retention, deletion, and appeals flows exist.
- [ ] Test accounts and rollback build are documented.
