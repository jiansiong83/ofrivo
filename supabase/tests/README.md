# Step 2 SQL verification

The repository does not have the Supabase CLI, Docker, or `psql` available in the current environment. `validate_step2.mjs` therefore performs a deterministic source-contract check only; it does not claim that PostgreSQL accepted the migration.

When a Supabase local runtime is available:

1. Start an isolated local project.
2. Apply `migrations/20260804000100_step2_foundation.sql`.
3. Apply `seed.sql`.
4. Run the scenarios in `step2_security_and_concurrency.sql` from separate authenticated sessions.

The fixture identities are documented in the SQL file. Do not use the local fixture passwords in any hosted environment.

