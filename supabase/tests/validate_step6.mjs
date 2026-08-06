import { readFile } from 'node:fs/promises';

const migration = await readFile(new URL('../migrations/20260804000600_provider_job_feed.sql', import.meta.url), 'utf8');
const models = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_job_models.dart', import.meta.url), 'utf8');
const repository = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_job_repository.dart', import.meta.url), 'utf8');
const controller = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_job_controller.dart', import.meta.url), 'utf8');
const screens = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_screens.dart', import.meta.url), 'utf8');
const localization = await readFile(new URL('../../apps/mobile/lib/core/localization/app_localization.dart', import.meta.url), 'utf8');

const checks = [
  ['transaction wrapper', /^begin;[\s\S]*commit;\s*$/m.test(migration.trim())],
  ['public feed labels', migration.includes('category_name') && migration.includes('area_name')],
  ['feed photo paths', migration.includes('photo_paths') && migration.includes('job_photos')],
  ['full address hidden', !migration.includes('j.full_address') && !migration.includes('j.contact_phone')],
  ['feed provider eligibility', migration.includes('public.is_approved_provider()')],
  ['filter model', models.includes('class ProviderJobFilters') && models.includes('ProviderJobSort')],
  ['bid validation', models.includes('class BidDraft') && models.includes('Enter a bid amount greater than RM0.')],
  ['fake bid lifecycle', repository.includes('class FakeProviderJobRepository') && repository.includes('withdrawBid')],
  ['Supabase public feed repository', repository.includes("from('public_job_feed')")],
  ['Supabase private photo signing', repository.includes("from('job-photos')") && repository.includes('createSignedUrl')],
  ['provider controller', controller.includes('providerJobControllerProvider') && controller.includes('submitBid')],
  ['feed filters UI', screens.includes('ProviderFiltersScreen') && (screens.includes('No bids yet') || localization.includes("'no_bids'"))],
  ['bid edit and withdraw UI', (screens.includes('Edit your bid') || localization.includes("'edit_bid'")) && (screens.includes('Withdraw bid') || localization.includes("'withdraw_bid'"))],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 6 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 6 contract validation passed: ${checks.length} migration/mobile checks.`);
