import { readFile } from 'node:fs/promises';

const migration = await readFile(new URL('../migrations/20260804000500_provider_application.sql', import.meta.url), 'utf8');
const models = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_application_models.dart', import.meta.url), 'utf8');
const repository = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_application_repository.dart', import.meta.url), 'utf8');

const checks = [
  ['provider work photo table', migration.includes('create table if not exists public.provider_work_photos')],
  ['work photo RLS', migration.includes('alter table public.provider_work_photos enable row level security')],
  ['direct provider insert restricted to not applied', migration.includes("verification_status = 'not_applied'")],
  ['server application RPC', migration.includes('create or replace function public.submit_provider_application(')],
  ['identity path ownership', migration.includes('verification files must belong to the authenticated provider')],
  ['category and area validation', migration.includes('one or more service categories are invalid') && migration.includes('one or more service areas are invalid')],
  ['private verification bucket path', repository.includes("from('provider-verifications')")],
  ['application status model', models.includes('enum ProviderApplicationStatus')],
  ['required identity validation', models.includes('Upload the front of your ID.') && models.includes('Upload the back of your ID.') && models.includes('Upload a verification selfie.')],
  ['work photo limit', models.includes('workPhotoPaths.length > 6')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 5 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 5 contract validation passed: ${checks.length} migration/mobile checks.`);
