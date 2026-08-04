import { readFile } from 'node:fs/promises';

const migration = await readFile(new URL('../migrations/20260804000100_step2_foundation.sql', import.meta.url), 'utf8');
const bidRepository = await readFile(new URL('../../apps/mobile/lib/features/customer/customer_bid_repository.dart', import.meta.url), 'utf8');
const bidController = await readFile(new URL('../../apps/mobile/lib/features/customer/customer_bid_controller.dart', import.meta.url), 'utf8');
const customerScreens = await readFile(new URL('../../apps/mobile/lib/features/customer/customer_screens.dart', import.meta.url), 'utf8');
const providerRepository = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_job_repository.dart', import.meta.url), 'utf8');
const notifications = await readFile(new URL('../../apps/mobile/lib/features/notifications/notification_repository.dart', import.meta.url), 'utf8');

const checks = [
  ['owner check', migration.includes('only the job owner can accept a bid')],
  ['job row lock', migration.includes('from public.jobs where id = p_job_id for update')],
  ['pending bid check', migration.includes("v_bid.status <> 'pending'")],
  ['other bids rejected', migration.includes("set status = 'rejected'") && migration.includes("status = 'pending'")],
  ['assigned state and audit', migration.includes("status = 'assigned', accepted_bid_id") && migration.includes("'bid_accepted'")],
  ['accept notifications', migration.includes("'bid_accepted'") && migration.includes("'job_assigned'")],
  ['authenticated RPC grant', migration.includes('grant execute on function public.accept_bid(uuid, uuid) to authenticated')],
  ['customer RPC integration', bidRepository.includes("rpc('accept_bid'")],
  ['fake atomic acceptance', bidRepository.includes('This offer is no longer pending') && bidRepository.includes('BidStatus.rejected')],
  ['received bid controller', bidController.includes('customerBidControllerProvider') && bidController.includes('accept(')],
  ['received bids UI', customerScreens.includes('ReceivedBidsScreen') && customerScreens.includes('Accept this offer')],
  ['provider address reveal path', providerRepository.includes('loadAssignedJobs') && providerRepository.includes('fullAddress')],
  ['notification repository', notifications.includes("from('notifications')") && notifications.includes('markRead')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 7 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 7 contract validation passed: ${checks.length} RPC/mobile checks.`);
