import { readFile } from 'node:fs/promises';

const page = await readFile(new URL('../../apps/admin/app/page.tsx', import.meta.url), 'utf8');
const data = await readFile(new URL('../../apps/admin/lib/admin-data.ts', import.meta.url), 'utf8');
const repository = await readFile(new URL('../../apps/admin/lib/admin-repository.ts', import.meta.url), 'utf8');
const client = await readFile(new URL('../../apps/admin/lib/supabase.ts', import.meta.url), 'utf8');
const packageJson = await readFile(new URL('../../apps/admin/package.json', import.meta.url), 'utf8');
const migration = await readFile(new URL('../migrations/20260805000600_admin_local_integration.sql', import.meta.url), 'utf8');
const taxonomy = page.slice(page.indexOf('function TaxonomyView'), page.indexOf('function LegacyTaxonomyView'));

const requiredTabs = ['Dashboard', 'Pending Providers', 'Users', 'Jobs', 'Bids', 'Reports', 'Audit Log'];
const checks = [
  ['admin login gate', page.includes('AdminLogin') && page.includes('signInAdmin') && page.includes('restoreAdminSession')],
  ['required admin tabs', requiredTabs.every((tab) => page.includes(`'${tab}'`))],
  ['provider verification actions', page.includes('providerAction') && page.includes("'approved'") && page.includes("'rejected'") && page.includes("'suspended'")],
  ['account suspend/restore', page.includes('userAction') && page.includes("'active'") && page.includes("'suspended'")],
  ['report review actions', page.includes('reportAction') && page.includes("'reviewing'") && page.includes("'resolved'") && page.includes("'dismissed'")],
  ['private evidence boundary', page.includes('Private evidence') && page.includes('Open signed URL') && page.includes('URLs expire after five minutes')],
  ['private job detail boundary', page.includes('Private address') && page.includes('fullAddress')],
  ['real data repository', repository.includes("rpc('admin_list_users')") && repository.includes("from('provider_profiles')") && repository.includes("from('jobs')") && repository.includes("from('bids')") && repository.includes("from('reports')") && repository.includes("from('admin_audit_events')")],
  ['real mutation repository', repository.includes("rpc('admin_review_provider'") && repository.includes("rpc('admin_update_account_status'") && repository.includes("rpc('admin_review_report'")],
  ['signed evidence storage', repository.includes("storage.from('provider-verifications').createSignedUrl") && repository.includes('300')],
  ['admin data contract', data.includes('export interface AdminData') && data.includes('providers:') && data.includes('reports:')],
  ['admin schema and rpc boundary', migration.includes('admin_audit_events') && migration.includes('admin_list_users') && migration.includes('admin_review_provider') && migration.includes('admin_update_account_status') && migration.includes('admin_review_report') && migration.includes('is_admin()')],
  ['runtime anon-only boundary', client.includes('NEXT_PUBLIC_SUPABASE_URL') && client.includes('NEXT_PUBLIC_SUPABASE_ANON_KEY') && !client.includes('service_role') && page.includes('Never exposed to browser')],
  ['supabase client dependency', packageJson.includes('"@supabase/supabase-js"')],
  ['taxonomy actions read-only', taxonomy.includes('Read-only') && !taxonomy.includes('Add {title ===') && !taxonomy.includes('>Disable</button>')],
  ['desktop layout builder', page.includes('hidden min-h-screen lg:flex') && page.includes('variant="desktop"') && page.includes('lg:grid-cols-[1.3fr_0.7fr]')],
  ['tablet layout builder', page.includes('hidden min-h-screen md:flex lg:hidden') && page.includes('variant="tablet"') && page.includes('TabletJobDrawer')],
  ['phone layout builder', page.includes('min-h-screen md:hidden') && page.includes('MobileAdminShell') && page.includes("renderContent('mobile')")],
  ['phone job list and detail', page.includes('MobileJobList') && page.includes('MobileJobDetail') && page.includes('Open admin navigation')],
  ['job detail remains admin-only', page.includes('Private address') && page.includes('JobDetailCard')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 9 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 9 contract validation passed: ${checks.length} admin web checks.`);
