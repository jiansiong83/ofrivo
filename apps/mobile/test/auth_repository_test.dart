import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/features/auth/auth_models.dart';
import 'package:ofrivo_mobile/features/auth/auth_repository.dart';

void main() {
  test('demo repository restores a local session without Supabase', () async {
    final repository = FakeAuthRepository();
    final user = await repository.restoreSession();
    final profile = await repository.ensureProfile(user!);

    expect(user.email, 'demo@ofrivo.local');
    expect(profile?.isApprovedProvider, isTrue);
    expect(profile?.isSuspended, isFalse);
  });

  test('demo account profile data follows the signed-in identity', () async {
    final repository = FakeAuthRepository();
    final customerResult = await repository.signIn(
        email: 'customer@example.test', password: 'local-dev-only');
    final customer = await repository.ensureProfile(customerResult.user!);
    final providerResult = await repository.signIn(
        email: 'provider@example.test', password: 'local-dev-only');
    final provider = await repository.ensureProfile(providerResult.user!);

    expect(customerResult.user?.id, isNot(providerResult.user?.id));
    expect(customer?.fullName, 'Alex Tan');
    expect(customer?.isApprovedProvider, isFalse);
    expect(provider?.fullName, 'Ahmad Plumbing');
    expect(provider?.isApprovedProvider, isTrue);
  });
  test('profile parser keeps sensitive fields out of public provider shape',
      () {
    final profile = ProfileData.fromMap({
      'id': 'user-1',
      'full_name': 'Alex Tan',
      'account_status': 'active',
      'is_admin': false,
      'provider_profiles': {'verification_status': 'pending'},
    });

    expect(profile.id, 'user-1');
    expect(profile.providerVerificationStatus, 'pending');
    expect(profile.isApprovedProvider, isFalse);
  });

  test('suspended profile is represented as a blocked state', () {
    final profile = ProfileData.fromMap(
        {'id': 'suspended-user', 'account_status': 'suspended'});
    expect(profile.isSuspended, isTrue);
  });

  test('customer and provider profile data stay isolated by account id', () {
    final customer = ProfileData.fromMap({
      'id': 'customer-a',
      'full_name': 'Customer A',
      'account_status': 'active',
      'provider_profiles': null,
    });
    final provider = ProfileData.fromMap({
      'id': 'provider-b',
      'full_name': 'Provider B',
      'account_status': 'active',
      'provider_profiles': {'verification_status': 'approved'},
    });

    expect(customer.id, isNot(provider.id));
    expect(customer.isApprovedProvider, isFalse);
    expect(provider.isApprovedProvider, isTrue);
  });

  test(
      'demo phone OTP validates the number and accepts the documented demo code',
      () async {
    final repository = FakeAuthRepository();

    expect(await repository.requestPhoneOtp('012 000 0101'),
        contains('valid phone'));
    expect(await repository.requestPhoneOtp('+60 12 000 0101'), isNull);
    expect(
        (await repository.verifyPhoneOtp(
                phone: '+60 12 000 0101', token: '000000'))
            .error,
        contains('not valid'));

    final result = await repository.verifyPhoneOtp(
        phone: '+60 12 000 0101', token: '123456');
    final profile = await repository.ensureProfile(result.user!);
    expect(result.succeeded, isTrue);
    expect(result.user?.phone, '+60120000101');
    expect(profile?.phone, '+60120000101');
  });

  test('demo phone OTP requires a fresh request before verification', () async {
    final repository = FakeAuthRepository();
    final result =
        await repository.verifyPhoneOtp(phone: '+60120000101', token: '123456');

    expect(result.succeeded, isFalse);
    expect(result.error, contains('Request a new'));
  });
}
