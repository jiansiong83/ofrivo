import { readFile } from 'node:fs/promises';

const migration = await readFile(new URL('../migrations/20260805000100_step10_push_notifications.sql', import.meta.url), 'utf8');
const foundation = await readFile(new URL('../migrations/20260804000100_step2_foundation.sql', import.meta.url), 'utf8');
const seed = await readFile(new URL('../seed.sql', import.meta.url), 'utf8');
const models = await readFile(new URL('../../apps/mobile/lib/core/models/app_models.dart', import.meta.url), 'utf8');
const appConfig = await readFile(new URL('../../apps/mobile/lib/core/config/app_config.dart', import.meta.url), 'utf8');
const tokenRepository = await readFile(new URL('../../apps/mobile/lib/features/notifications/device_token_repository.dart', import.meta.url), 'utf8');
const tokenSource = await readFile(new URL('../../apps/mobile/lib/features/notifications/device_token_source.dart', import.meta.url), 'utf8');
const registration = await readFile(new URL('../../apps/mobile/lib/features/notifications/push_registration_controller.dart', import.meta.url), 'utf8');
const notifications = await readFile(new URL('../../apps/mobile/lib/features/notifications/notification_repository.dart', import.meta.url), 'utf8');
const controller = await readFile(new URL('../../apps/mobile/lib/features/notifications/notification_controller.dart', import.meta.url), 'utf8');
const shell = await readFile(new URL('../../apps/mobile/lib/features/shell/shell_screen.dart', import.meta.url), 'utf8');
const tests = await readFile(new URL('../../apps/mobile/test/notification_test.dart', import.meta.url), 'utf8');

const checks = [
  ['device token RPCs', migration.includes('register_device_token') && migration.includes('unregister_device_token') && migration.includes('on conflict (token)')],
  ['new job trigger', migration.includes('notify_new_job_event') && migration.includes("'new_job'") && migration.includes('jobs_notify_new_job')],
  ['new bid trigger', migration.includes('notify_new_bid_event') && migration.includes("'new_bid'") && migration.includes('bids_notify_new_bid')],
  ['verification result trigger', migration.includes('notify_provider_verification_event') && migration.includes("'provider_rejected'") && migration.includes('provider_verifications_notify_result')],
  ['transactional accepted/lifecycle events', foundation.includes("'bid_accepted'") && foundation.includes("'job_assigned'") && foundation.includes("'job_started'") && foundation.includes("'job_completed'") && foundation.includes("'job_cancelled'")],
  ['expiry scheduler function', migration.includes('queue_job_expiring_notifications') && migration.includes("'job_expiring'") && migration.includes('20 hours')],
  ['RPC grants and scheduler boundary', migration.includes('grant execute on function public.register_device_token') && migration.includes('revoke all on function public.queue_job_expiring_notifications')],
  ['seed device token', seed.includes('insert into public.device_tokens') && seed.includes("'android'")],
  ['notification event model', models.includes('newJob') && models.includes('jobExpiring') && models.includes('providerRejected') && models.includes('providerSuspended')],
  ['runtime token contract', appConfig.includes('PUSH_DEVICE_TOKEN') && appConfig.includes('PUSH_PLATFORM') && tokenSource.includes('RuntimeDeviceTokenSource')],
  ['token repository adapters', tokenRepository.includes('FakeDeviceTokenRepository') && tokenRepository.includes("rpc('register_device_token'") && tokenRepository.includes("rpc('unregister_device_token'")],
  ['registration lifecycle', registration.includes('pushRegistrationControllerProvider') && registration.includes('tokenRefreshes') && registration.includes('unregister')],
  ['notification read state', notifications.includes('markAllRead') && controller.includes('markAllRead')],
  ['unread badge', shell.includes('unreadCount') && shell.includes('_NotificationIcon')],
  ['push tests', tests.includes('device token registration') && tests.includes('push registration controller')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 10 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 10 contract validation passed: ${checks.length} push notification checks.`);
