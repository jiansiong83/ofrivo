# Step 2 SQL verification

The repository includes a local Supabase configuration. The CLI runs through the cached `supabase@2.109.1` package and Docker Desktop; the Ofrivo stack uses ports `54420`–`54427` so it can run beside other local projects. `validate_step2.mjs` remains a deterministic source-contract check, while the local integration runner exercises PostgreSQL and PostgREST behavior.

When a Supabase local runtime is available:

1. Start an isolated local project.
2. Apply `migrations/20260804000100_step2_foundation.sql`.
3. Apply `seed.sql`.
4. Run the scenarios in `step2_security_and_concurrency.sql` from separate authenticated sessions.

The fixture identities are documented in the SQL file. Do not use the local fixture passwords in any hosted environment.

`validate_step5.mjs` checks the provider application migration, server RPC, private verification path, and mobile validation contracts.

## Step 11 security and resilience verification

`step11_security_and_testing.sql` documents the manual RLS, private Storage, multiple-account privacy, invalid-transition, and concurrent bid-acceptance scenarios. `run_step11_local.mjs` is the executable local suite; it logs in with seeded Auth identities and checks the same boundaries through PostgREST and Storage.

Start the local stack and run the executable suite with:

```text
npx.cmd --yes supabase@2.109.1 start
npx.cmd --yes supabase@2.109.1 status --output env
node supabase/tests/run_step11_local.mjs
```

The runner expects `SUPABASE_LOCAL_API_URL`, `SUPABASE_LOCAL_ANON_KEY`, and `SUPABASE_LOCAL_SERVICE_ROLE_KEY` from the status output. The service key is used only to reset local concurrency fixtures; it is never committed or passed to the mobile app. The current local Docker run passed 19 integration checks. Hosted Supabase permission tests remain environment-gated.

The Flutter side of Step 11 is automated locally:

- `test/image_validation_test.dart` checks extension/signature, size, count, duplicate, and missing-file boundaries.
- `test/widget_smoke_test.dart` checks retryable error and offline states.
- `test/security_smoke_test.dart` checks crash diagnostic capture.
- `test/auth_repository_test.dart` checks customer/provider account isolation.

Run the static contract validator with:

```text
node supabase/tests/validate_step11.mjs
```
