import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const migration = readFileSync(resolve(root, 'migrations/20260804000100_step2_foundation.sql'), 'utf8');
const seed = readFileSync(resolve(root, 'seed.sql'), 'utf8');

const requiredMigrationTokens = [
  'create table if not exists public.profiles',
  'create table if not exists public.provider_profiles',
  'create table if not exists public.jobs',
  'create table if not exists public.bids',
  'create table if not exists public.reviews',
  'create table if not exists public.reports',
  'create table if not exists public.notifications',
  'create table if not exists public.device_tokens',
  'create table if not exists public.job_events',
  'bids_one_active_per_provider_job',
  'bids_one_accepted_per_job',
  'create policy jobs_select_owner_admin_assigned',
  'create policy bids_insert_approved_provider',
  'create policy provider_verifications_self_or_admin',
  'create policy job_photos_read_authorized',
  'create policy report_evidence_reporter_admin',
  'public.public_job_feed',
  'public.public_provider_directory',
  'provider-verifications',
  'report-evidence',
  'alter table public.profiles enable row level security',
  'alter table public.job_events enable row level security',
  'create trigger reports_validate_participants',
  'create or replace function public.accept_bid',
  'create or replace function public.start_job',
  'create or replace function public.complete_job',
  'create or replace function public.cancel_job',
  'for update',
  'for update',
  'for update',
];

const requiredSeedTokens = [
  'customer@example.test',
  'provider@example.test',
  'pending-provider@example.test',
  'provider-b@example.test',
  'admin@example.test',
  'plumbing-toilet',
  'electrical-lighting-fan',
  'air-conditioning',
  'moving-delivery',
  'cleaning',
  'handyman',
  "'open'",
  "'pending'",
  "'assigned'",
  "'accepted'",
];

const missing = (source, tokens) => tokens.filter((token) => !source.includes(token));
const missingMigration = missing(migration, requiredMigrationTokens);
const missingSeed = missing(seed, requiredSeedTokens);

if (!/^begin;[\s\S]*commit;\s*$/m.test(migration.trim())) {
  console.error('Migration must be wrapped in a transaction.');
  process.exitCode = 1;
}
if (!/^begin;[\s\S]*commit;\s*$/m.test(seed.trim())) {
  console.error('Seed must be wrapped in a transaction.');
  process.exitCode = 1;
}
if (migration.includes('SUPABASE_SERVICE_ROLE_KEY') || seed.includes('SUPABASE_SERVICE_ROLE_KEY')) {
  console.error('Database source must not contain service-role environment values.');
  process.exitCode = 1;
}
if (missingMigration.length || missingSeed.length) {
  if (missingMigration.length) console.error('Missing migration contracts:', missingMigration);
  if (missingSeed.length) console.error('Missing seed fixtures:', missingSeed);
  process.exitCode = 1;
}
if ((migration.match(/enable row level security/g) ?? []).length !== 15) {
  console.error('Expected RLS to be enabled on all 15 planned user-data tables.');
  process.exitCode = 1;
}

if (!process.exitCode) {
  console.log(`Step 2 contract validation passed: ${requiredMigrationTokens.length} migration checks, ${requiredSeedTokens.length} seed checks.`);
}
