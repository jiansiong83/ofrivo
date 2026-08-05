import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), 'utf8');

const models = read('apps/mobile/lib/features/auth/auth_models.dart');
const repository = read('apps/mobile/lib/features/auth/auth_repository.dart');
const controller = read('apps/mobile/lib/features/auth/auth_controller.dart');
const screens = read('apps/mobile/lib/features/auth/auth_screens.dart');
const router = read('apps/mobile/lib/core/router/app_router.dart');
const tests = read('apps/mobile/test/auth_repository_test.dart');
const localization = read('apps/mobile/lib/core/localization/app_localization.dart');
const app = read('apps/mobile/lib/app.dart');
const onboarding = read('apps/mobile/lib/features/onboarding/onboarding_screen.dart');
const shell = read('apps/mobile/lib/features/shell/shell_screen.dart');
const localizationTests = read('apps/mobile/test/localization_test.dart');
const pubspec = read('apps/mobile/pubspec.yaml');
const portfolioMigration = read('supabase/migrations/20260805000200_version11_provider_portfolio.sql');
const appModels = read('apps/mobile/lib/core/models/app_models.dart');
const fakeData = read('apps/mobile/lib/core/data/fake_data.dart');
const bidRepository = read('apps/mobile/lib/features/customer/customer_bid_repository.dart');
const providerRepository = read('apps/mobile/lib/features/provider/provider_application_repository.dart');
const widgets = read('apps/mobile/lib/shared/widgets/app_widgets.dart');
const customerScreens = read('apps/mobile/lib/features/customer/customer_screens.dart');
const providerScreens = read('apps/mobile/lib/features/provider/provider_screens.dart');
const portfolioTests = read('apps/mobile/test/provider_portfolio_test.dart');
const noShowMigration = read('supabase/migrations/20260805000300_version11_no_show.sql');
const lifecycleModels = read('apps/mobile/lib/features/job_lifecycle/job_lifecycle_models.dart');
const lifecycleRepository = read('apps/mobile/lib/features/job_lifecycle/job_lifecycle_repository.dart');
const lifecycleController = read('apps/mobile/lib/features/job_lifecycle/job_lifecycle_controller.dart');
const lifecycleScreens = read('apps/mobile/lib/features/job_lifecycle/job_lifecycle_screens.dart');
const notificationModel = read('apps/mobile/lib/core/models/app_models.dart');
const notificationRepository = read('apps/mobile/lib/features/notifications/notification_repository.dart');
const lifecycleTests = read('apps/mobile/test/job_lifecycle_test.dart');
const noShowRunner = read('supabase/tests/run_version11_no_show_local.mjs');

const checks = [
  ['AuthUser carries an optional phone number', models.includes('final String? phone;')],
  ['repository exposes OTP request and verify operations', repository.includes('requestPhoneOtp') && repository.includes('verifyPhoneOtp')],
  ['phone input is normalized before Auth calls', repository.includes('normalizePhoneNumber') && repository.includes("startsWith('00')")],
  ['phone input is constrained to E.164 length and prefix', repository.includes("^\\+[1-9]\\d{7,14}$")],
  ['demo repository documents a deterministic OTP', repository.includes("token.trim() != '123456'")],
  ['demo repository stores the pending phone before verify', repository.includes('_pendingPhone = normalized')],
  ['demo repository rejects verification without a fresh request', repository.includes('Request a new verification code first.')],
  ['Supabase requests an SMS OTP', repository.includes('client.auth.signInWithOtp(phone: normalized)')],
  ['Supabase verifies SMS OTPs', repository.includes('verifyOTP(phone: normalized') && repository.includes('type: OtpType.sms')],
  ['Supabase maps the authenticated phone', repository.includes('phone: user.phone')],
  ['phone-only users receive a safe profile seed name', repository.includes("user.phone ?? 'Ofrivo member'")],
  ['controller exposes OTP request state', controller.includes('Future<String?> requestPhoneOtp(String phone)')],
  ['controller restores the profile after OTP verification', controller.includes('Future<bool> verifyPhoneOtp') && controller.includes('repository.ensureProfile(result.user!)')],
  ['phone sign-in has a dedicated route', router.includes("path: '/phone-login'")],
  ['login screen links to phone sign-in', screens.includes("context.push('/phone-login')")],
  ['phone screen supports sending and verifying a code', screens.includes('class PhoneOtpScreen') && screens.includes("text('send_code')") && screens.includes("text('verify_code')")],
  ['demo hint is visible only through the repository mode', screens.includes('authRepositoryProvider).isDemoMode')],
  ['phone OTP behavior has unit coverage', tests.includes('demo phone OTP validates') && tests.includes('requires a fresh request')],
  ['mobile auth source does not contain service-role credentials', !/service[_-]?role|SUPABASE_SERVICE_ROLE/i.test(repository)],
  ['three supported languages are declared', localization.includes('AppLanguage.english') && localization.includes('AppLanguage.malay') && localization.includes('AppLanguage.chinese')],
  ['language selection is persisted locally', localization.includes('SharedPreferences') && localization.includes("ofrivo.language")],
  ['translations include English, Malay, and Chinese copy', localization.includes('AppLanguage.malay:') && localization.includes('AppLanguage.chinese:')],
  ['language provider exposes reactive app state', localization.includes('appLanguageProvider') && localization.includes('StateNotifierProvider')],
  ['MaterialApp follows the selected locale', app.includes('locale: language.locale')],
  ['onboarding exposes the language picker', onboarding.includes('LanguagePicker(showLabel: true)') && onboarding.includes("text('onboarding_title')")],
  ['auth screens react to language changes', screens.includes('appLanguageProvider') && screens.includes('LanguagePicker()')],
  ['shell navigation reacts to language changes', shell.includes('appLanguageProvider') && shell.includes("text('job_feed')")],
  ['localization has language and fallback tests', localizationTests.includes('three supported languages') && localizationTests.includes('falls back to English')],
  ['shared preferences is a direct mobile dependency', pubspec.includes('shared_preferences: ^2.5.5')],
  ['portfolio bucket is public-read and owner-write', portfolioMigration.includes("'provider-portfolio'") && portfolioMigration.includes('provider_portfolio_public_read') && portfolioMigration.includes('provider_portfolio_owner_write')],
  ['public portfolio view filters approved active providers', portfolioMigration.includes('public_provider_portfolio') && portfolioMigration.includes("verification_status = 'approved'") && portfolioMigration.includes("account_status = 'active'")],
  ['portfolio view exposes paths without private verification fields', portfolioMigration.includes('photo_paths') && !portfolioMigration.includes('provider_verifications.')],
  ['provider model carries portfolio URLs', appModels.includes('portfolioUrls')],
  ['fake approved providers include portfolio fixtures', fakeData.includes('portfolio-plumbing-1.jpg') && fakeData.includes('portfolio-handyman-1.jpg')],
  ['customer repository maps public portfolio URLs', bidRepository.includes('public_provider_portfolio') && bidRepository.includes("getPublicUrl(path)")],
  ['provider application uploads work photos to the public portfolio bucket', providerRepository.includes("bucket: 'provider-portfolio'") && providerRepository.includes("from('provider-portfolio')")],
  ['portfolio gallery handles local placeholders and remote images', widgets.includes('class PortfolioGallery') && widgets.includes('Image.network') && widgets.includes('Work photo')],
  ['customer and provider profile screens render portfolio galleries', customerScreens.includes('PortfolioGallery') && providerScreens.includes('PortfolioGallery')],
  ['portfolio has model and widget coverage', portfolioTests.includes('approved demo providers') && portfolioTests.includes('portfolio gallery renders')],
  ['no-show RPC restricts state and participants', noShowMigration.includes('mark_no_show') && noShowMigration.includes("v_job.status not in ('assigned', 'in_progress')") && noShowMigration.includes('only the customer or accepted provider')],
  ['no-show RPC prevents duplicate reports and notifies the reported user', noShowMigration.includes('a no-show has already been marked') && noShowMigration.includes("'no_show'") && noShowMigration.includes('notifications')],
  ['no-show RPC is authenticated-only', noShowMigration.includes('revoke all on function public.mark_no_show') && noShowMigration.includes('grant execute on function public.mark_no_show(uuid, text) to authenticated')],
  ['lifecycle repository exposes no-show marker', lifecycleRepository.includes('Future<JobEventRecord> markNoShow')],
  ['fake and Supabase repositories implement no-show marker', lifecycleRepository.includes('No-show reported by a job participant') && lifecycleRepository.includes("client.rpc('mark_no_show'")],
  ['lifecycle controller and actions expose no-show state', lifecycleController.includes('Future<bool> markNoShow') && lifecycleScreens.includes('Mark provider no-show') && lifecycleScreens.includes('Report customer no-show')],
  ['no-show notification maps to a typed mobile event', notificationModel.includes('noShow') && notificationRepository.includes("case 'no_show'")],
  ['job lifecycle tests cover no-show authorization and duplicate guard', lifecycleTests.includes('no-show')],
  ['local no-show runner covers RPC, duplicate, event, and notification paths', noShowRunner.includes("/rpc/mark_no_show") && noShowRunner.includes('duplicate no-show marker') && noShowRunner.includes('reported-user notification')],
];

const failures = checks.filter(([, passed]) => !passed);
for (const [label, passed] of checks) console.log(`${passed ? 'PASS' : 'FAIL'} ${label}`);

if (failures.length > 0) {
  console.error(`\n${failures.length} Version 1.1 contract check(s) failed.`);
  process.exitCode = 1;
} else {
  console.log(`\n${checks.length} Version 1.1 contract checks passed.`);
}
