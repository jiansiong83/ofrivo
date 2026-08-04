import { readFile } from 'node:fs/promises';

const page = await readFile(new URL('../../apps/admin/app/page.tsx', import.meta.url), 'utf8');
const data = await readFile(new URL('../../apps/admin/lib/admin-data.ts', import.meta.url), 'utf8');

const requiredTabs = ['Dashboard', 'Pending Providers', 'Users', 'Jobs', 'Bids', 'Reports', 'Audit Log'];
const checks = [
  ['admin login gate', page.includes('AdminLogin') && page.includes('signedIn') && page.includes('setSignedIn(false)')],
  ['required admin tabs', requiredTabs.every((tab) => page.includes(`'${tab}'`))],
  ['provider verification actions', page.includes('providerAction') && page.includes("'approved'") && page.includes("'rejected'") && page.includes("'suspended'")],
  ['account suspend/restore', page.includes('userAction') && page.includes("'active'") && page.includes("'suspended'")],
  ['report review actions', page.includes('reportAction') && page.includes("'reviewing'") && page.includes("'resolved'") && page.includes("'dismissed'")],
  ['private evidence boundary', page.includes('Private evidence') && page.includes('Signed preview') && page.includes('short-lived signed URLs')],
  ['private job detail boundary', page.includes('Private address') && page.includes('fullAddress')],
  ['audit trail mutation', page.includes('next.audit.unshift') && page.includes('createdAt: \'Just now\'')],
  ['fake admin data contract', data.includes('export interface AdminData') && data.includes('makeFakeAdminData') && data.includes('providers:') && data.includes('reports:')],
  ['runtime secret boundary', page.includes('Never exposed to browser') && !page.includes('service_role')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 9 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 9 contract validation passed: ${checks.length} admin web checks.`);
