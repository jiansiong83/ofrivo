import { readFile } from 'node:fs/promises';

const foundation = await readFile(new URL('../migrations/20260804000100_step2_foundation.sql', import.meta.url), 'utf8');
const providerApplication = await readFile(new URL('../migrations/20260804000500_provider_application.sql', import.meta.url), 'utf8');
const pushMigration = await readFile(new URL('../migrations/20260805000100_step10_push_notifications.sql', import.meta.url), 'utf8');
const scenarios = await readFile(new URL('./step11_security_and_testing.sql', import.meta.url), 'utf8');
const imageValidation = await readFile(new URL('../../apps/mobile/lib/core/validation/image_validation.dart', import.meta.url), 'utf8');
const crashReporter = await readFile(new URL('../../apps/mobile/lib/core/diagnostics/app_crash_reporter.dart', import.meta.url), 'utf8');
const main = await readFile(new URL('../../apps/mobile/lib/main.dart', import.meta.url), 'utf8');
const widgets = await readFile(new URL('../../apps/mobile/lib/shared/widgets/app_widgets.dart', import.meta.url), 'utf8');
const customerScreen = await readFile(new URL('../../apps/mobile/lib/features/customer/customer_screens.dart', import.meta.url), 'utf8');
const providerScreen = await readFile(new URL('../../apps/mobile/lib/features/provider/provider_screens.dart', import.meta.url), 'utf8');
const imageTests = await readFile(new URL('../../apps/mobile/test/image_validation_test.dart', import.meta.url), 'utf8');
const securityTests = await readFile(new URL('../../apps/mobile/test/security_smoke_test.dart', import.meta.url), 'utf8');
const authTests = await readFile(new URL('../../apps/mobile/test/auth_repository_test.dart', import.meta.url), 'utf8');
const widgetTests = await readFile(new URL('../../apps/mobile/test/widget_smoke_test.dart', import.meta.url), 'utf8');

const checks = [
  ['RLS coverage', (foundation.match(/alter table public\..+ enable row level security/g) ?? []).length === 15 && foundation.includes('create policy jobs_select_owner_admin_assigned')],
  ['Storage privacy policies', foundation.includes('job_photos_read_authorized') && foundation.includes('provider_verifications_owner_admin') && foundation.includes('report_evidence_reporter_admin')],
  ['provider work-photo RLS', providerApplication.includes('alter table public.provider_work_photos enable row level security') && providerApplication.includes('provider_work_photos_select_self_or_admin')],
  ['multi-account SQL scenario', scenarios.includes('RLS-01') && scenarios.includes('ACCOUNT-01') && scenarios.includes('Session A') && scenarios.includes('Session B')],
  ['storage SQL scenario', scenarios.includes('STORAGE-01') && scenarios.includes('short-lived signed URL')],
  ['concurrency SQL scenario', scenarios.includes('CONCURRENCY-01') && scenarios.includes('accept_bid') && scenarios.includes('one success')],
  ['error/offline/crash/image scenario map', ['ERROR-01', 'OFFLINE-01', 'CRASH-01', 'IMAGE-01'].every((token) => scenarios.includes(token))],
  ['image file validation', imageValidation.includes('defaultMaxBytes') && imageValidation.includes('_matchesSignature') && imageValidation.includes('validatePaths')],
  ['image validation wired to pickers', customerScreen.includes('ImageValidation.validatePaths') && providerScreen.includes('ImageValidation.validatePath')],
  ['retryable error and offline UI', widgets.includes('onAction: onRetry') && widgets.includes('class OfflineState') && widgets.includes('OutlinedButton')],
  ['global crash handlers', crashReporter.includes('AppCrashReporter') && main.includes('FlutterError.onError') && main.includes('PlatformDispatcher.instance.onError')],
  ['image tests', imageTests.includes('spoofed extension') && imageTests.includes('size boundaries')],
  ['crash test', securityTests.includes('crash reporter keeps the last error')],
  ['multiple account test', authTests.includes('customer and provider profile data stay isolated')],
  ['widget resilience test', widgetTests.includes('error and offline states expose a retry action')],
  ['server token boundary', pushMigration.includes('register_device_token') && pushMigration.includes('revoke all on function public.queue_job_expiring_notifications') && !pushMigration.includes('SUPABASE_SERVICE_ROLE_KEY')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 11 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 11 contract validation passed: ${checks.length} security/testing checks.`);
