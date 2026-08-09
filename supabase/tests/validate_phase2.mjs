import fs from 'node:fs';

const checks = [];

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function pass(label, condition) {
  if (!condition) throw new Error(`${label} failed`);
  checks.push(label);
  console.log(`PASS ${label}`);
}

const migration = read('supabase/migrations/20260809000100_provider_display_name_role_separation.sql');
const authModels = read('apps/mobile/lib/features/auth/auth_models.dart');
const authRepository = read('apps/mobile/lib/features/auth/auth_repository.dart');
const providerApplicationController = read('apps/mobile/lib/features/provider/provider_application_controller.dart');
const providerApplicationRepository = read('apps/mobile/lib/features/provider/provider_application_repository.dart');
const providerJobController = read('apps/mobile/lib/features/provider/provider_job_controller.dart');
const providerScreens = read('apps/mobile/lib/features/provider/provider_screens.dart');
const adminRepository = read('apps/admin/lib/admin-repository.ts');
const seed = read('supabase/seed.sql');

pass('provider profile has a separate display name column',
  /alter table public\.provider_profiles[\s\S]*add column if not exists display_name text/.test(migration));
pass('provider directory prefers provider business name',
  migration.includes('coalesce(pp.display_name, p.display_name, p.full_name)'));
pass('legacy provider application RPC is private',
  migration.includes('submit_provider_application_legacy') &&
    migration.includes('revoke all on function public.submit_provider_application_legacy'));
pass('legacy provider update RPC is private',
  migration.includes('update_provider_profile_legacy') &&
    migration.includes('revoke all on function public.update_provider_profile_legacy'));
pass('provider RPC restores the customer profile name',
  (migration.match(/set display_name = v_customer_display_name/g) ?? []).length >= 2);
pass('profile model exposes provider display name separately',
  authModels.includes('providerDisplayName') &&
    authModels.includes("providerMap['display_name']"));
pass('Supabase auth hydrates provider display name',
  authRepository.includes('provider_profiles(display_name,verification_status)'));
pass('fake provider application uses provider display name',
  providerApplicationController.includes('auth.profile?.providerDisplayName'));
pass('real provider application reads provider display name',
  providerApplicationRepository.includes('user_id,display_name,bio') &&
    providerApplicationRepository.includes("providerRow?['display_name']"));
pass('fake provider jobs are scoped to the signed-in provider',
  providerJobController.includes('fakeJobsForProvider(providerId') &&
    providerJobController.includes('demoProviderSeedIdForUser(providerId)'));
pass('provider detail has no unscoped fake-job fallback',
  !providerScreens.includes('for (final candidate in fakeJobs)'));
pass('Admin loads provider business names separately',
  adminRepository.includes("provider_profiles').select('user_id, display_name") &&
    adminRepository.includes('const accountName') &&
    adminRepository.includes('const providerName'));
pass('seed fixtures populate provider display names',
  seed.includes('provider_profiles (user_id, display_name, bio'));

console.log(`Phase 2 static validation passed: ${checks.length} checks.`);
