# Step 2 SQL verification

The repository does not have the Supabase CLI, Docker, or `psql` available in the current environment. `validate_step2.mjs` therefore performs a deterministic source-contract check only; it does not claim that PostgreSQL accepted the migration.

When a Supabase local runtime is available:

1. Start an isolated local project.
2. Apply `migrations/20260804000100_step2_foundation.sql`.
3. Apply `seed.sql`.
4. Run the scenarios in `step2_security_and_concurrency.sql` from separate authenticated sessions.

The fixture identities are documented in the SQL file. Do not use the local fixture passwords in any hosted environment.

`validate_step5.mjs` checks the provider application migration, server RPC, private verification path, and mobile validation contracts.

## Step 11 security and resilience verification

`step11_security_and_testing.sql` is the manual integration suite for RLS, private Storage, multiple-account privacy, and concurrent bid acceptance. It must run against an isolated Supabase local project with the migration and seed applied; the current workspace does not include Docker, PostgreSQL, or a Supabase CLI runtime, so the suite is intentionally documented rather than claimed as executed.

The Flutter side of Step 11 is automated locally:

- `test/image_validation_test.dart` checks extension/signature, size, count, duplicate, and missing-file boundaries.
- `test/widget_smoke_test.dart` checks retryable error and offline states.
- `test/security_smoke_test.dart` checks crash diagnostic capture.
- `test/auth_repository_test.dart` checks customer/provider account isolation.

Run the static contract validator with:

```text
node supabase/tests/validate_step11.mjs
```
