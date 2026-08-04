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

  test('profile parser keeps sensitive fields out of public provider shape', () {
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
    final profile = ProfileData.fromMap({'id': 'suspended-user', 'account_status': 'suspended'});
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
}
