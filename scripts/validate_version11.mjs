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
  ['phone screen supports sending and verifying a code', screens.includes('class PhoneOtpScreen') && screens.includes('Send code') && screens.includes('Verify code')],
  ['demo hint is visible only through the repository mode', screens.includes('authRepositoryProvider).isDemoMode')],
  ['phone OTP behavior has unit coverage', tests.includes('demo phone OTP validates') && tests.includes('requires a fresh request')],
  ['mobile auth source does not contain service-role credentials', !/service[_-]?role|SUPABASE_SERVICE_ROLE/i.test(repository)],
];

const failures = checks.filter(([, passed]) => !passed);
for (const [label, passed] of checks) console.log(`${passed ? 'PASS' : 'FAIL'} ${label}`);

if (failures.length > 0) {
  console.error(`\n${failures.length} Version 1.1 contract check(s) failed.`);
  process.exitCode = 1;
} else {
  console.log(`\n${checks.length} Version 1.1 contract checks passed.`);
}
