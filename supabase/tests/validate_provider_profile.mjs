import fs from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8');
const migration = read('supabase/migrations/20260806000100_provider_profile_category_approval.sql');
const models = read('apps/mobile/lib/features/provider/provider_application_models.dart');
const repository = read('apps/mobile/lib/features/provider/provider_application_repository.dart');
const controller = read('apps/mobile/lib/features/provider/provider_application_controller.dart');
const profile = read('apps/mobile/lib/features/provider/provider_screens.dart');
const editor = read('apps/mobile/lib/features/provider/provider_profile_edit_screen.dart');
const router = read('apps/mobile/lib/core/router/app_router.dart');
const adminRepo = read('apps/admin/lib/admin-repository.ts');
const adminPage = read('apps/admin/app/page.tsx');
const integration = read('supabase/tests/run_provider_profile_local.mjs');
const checks = [
  ['category status enum and metadata', migration.includes("create type public.provider_category_status") && migration.includes('reviewed_by') && migration.includes('admin_note')],
  ['category submission RPC', migration.includes('submit_provider_category_changes') && migration.includes("status = 'pending'")],
  ['category review RPC and audit', migration.includes('review_provider_category') && migration.includes('provider_category_review_') && migration.includes('admin_audit_events')],
  ['profile and availability RPCs', migration.includes('update_provider_profile') && migration.includes('set_provider_availability')],
  ['approved-only feed and availability', migration.includes("pc.status = 'approved'") && migration.includes('pp.is_available')],
  ['open-job access preserves assigned path', migration.includes('is_accepted_job_provider') && migration.includes('can_read_job')],
  ['mobile category status model', models.includes('ProviderCategoryStatus') && models.includes('ProviderCategorySelection')],
  ['mobile repository exposes profile/category/availability writes', repository.includes('updateProfile') && repository.includes('submitCategoryChanges') && repository.includes('setAvailability')],
  ['controller exposes profile actions', controller.includes('Future<ProviderApplication?> updateProfile') && controller.includes('setAvailability')],
  ['profile card is clickable', profile.includes("context.go('/provider/profile/edit')") && profile.includes('ProviderCard(')],
  ['profile editor has service and availability controls', editor.includes('Service categories') && editor.includes('Available for new jobs')],
  ['profile editor route exists', router.includes("path: '/provider/profile/edit'")],
  ['Admin reads category requests and reviews them', adminRepo.includes('categoryRequests') && adminRepo.includes('reviewProviderCategory') && adminRepo.includes("review_provider_category")],
  ['Admin category request UI exists', adminPage.includes("Category Requests") && adminPage.includes('Approve category') && adminPage.includes('Reject category')],
  ['integration runner covers RLS/feed/availability', integration.includes('provider cannot insert an approved category directly') && integration.includes('unavailable provider still reads an assigned job')],
];
const failures = checks.filter(([, ok]) => !ok);
if (failures.length) {
  console.error(`Provider Profile contract validation failed: ${failures.map(([label]) => label).join(', ')}`);
  process.exit(1);
}
console.log(`Provider Profile contract validation passed: ${checks.length} checks.`);