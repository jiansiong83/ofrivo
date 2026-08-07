import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'auth_models.dart';

abstract interface class AuthRepository {
  bool get isDemoMode;
  Future<AuthUser?> restoreSession();
  Future<ProfileData?> ensureProfile(AuthUser user);
  Future<AuthOperation> signIn(
      {required String email, required String password});
  Future<AuthOperation> register(
      {required String fullName,
      required String email,
      required String password});
  Future<String?> requestPhoneOtp(String phone);
  Future<AuthOperation> verifyPhoneOtp(
      {required String phone, required String token});
  Future<String?> resetPassword(String email);
  Future<String?> signOut();
}

String normalizePhoneNumber(String value) {
  var normalized = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (normalized.startsWith('00')) normalized = '+${normalized.substring(2)}';
  return normalized;
}

bool isValidPhoneNumber(String value) {
  final normalized = normalizePhoneNumber(value);
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository()
      : _user = const AuthUser(id: 'demo-user', email: 'demo@ofrivo.local');

  AuthUser? _user;
  String? _registeredFullName;
  String? _pendingPhone;

  @override
  bool get isDemoMode => true;

  @override
  Future<AuthUser?> restoreSession() async => _user;

  @override
  Future<ProfileData?> ensureProfile(AuthUser user) async {
    final email = user.email.trim().toLowerCase();
    final knownPhone = switch (email) {
      'customer@example.test' => '+60 12 000 0101',
      'provider@example.test' => '+60 12 000 0102',
      'pending-provider@example.test' => '+60 12 000 0103',
      'provider-b@example.test' => '+60 12 000 0104',
      'demo@ofrivo.local' => '+60 12 000 0101',
      _ => null,
    };
    final displayName = switch (email) {
      'customer@example.test' || 'demo@ofrivo.local' => 'Alex',
      'provider@example.test' => 'Ahmad Plumbing',
      'pending-provider@example.test' => 'Pending Provider',
      'provider-b@example.test' => 'JB Home Fix',
      'admin@example.test' => 'Ofrivo Admin',
      _ => _registeredFullName?.trim().isNotEmpty == true
          ? _registeredFullName!.trim()
          : authDisplayName(user, null),
    };
    final fullName = switch (email) {
      'customer@example.test' || 'demo@ofrivo.local' => 'Alex Tan',
      'provider@example.test' => 'Ahmad Plumbing',
      'pending-provider@example.test' => 'Pending Provider',
      'provider-b@example.test' => 'JB Home Fix',
      'admin@example.test' => 'Ofrivo Admin',
      _ => _registeredFullName?.trim().isNotEmpty == true
          ? _registeredFullName!.trim()
          : displayName,
    };
    return ProfileData(
      id: user.id,
      fullName: fullName,
      displayName: displayName,
      phone: user.phone ?? knownPhone,
      whatsapp: user.phone ?? knownPhone,
      accountStatus: 'active',
      isAdmin: email == 'admin@example.test',
      providerVerificationStatus: switch (email) {
        'provider@example.test' ||
        'provider-b@example.test' ||
        'demo@ofrivo.local' =>
          'approved',
        'pending-provider@example.test' => 'pending',
        _ => 'not_applied',
      },
    );
  }

  @override
  Future<AuthOperation> signIn(
      {required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthOperation(error: 'Enter your email and password.');
    }
    _registeredFullName = null;
    _user = AuthUser(id: _fakeUserId(email), email: email.trim());
    return AuthOperation(user: _user);
  }

  @override
  Future<AuthOperation> register(
      {required String fullName,
      required String email,
      required String password}) async {
    if (fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        password.length < 6) {
      return const AuthOperation(
          error:
              'Use a name, a valid email, and a password of at least 6 characters.');
    }
    _registeredFullName = fullName.trim();
    _user = AuthUser(id: _fakeUserId(email), email: email.trim());
    return AuthOperation(user: _user);
  }

  @override
  Future<String?> requestPhoneOtp(String phone) async {
    final normalized = normalizePhoneNumber(phone);
    if (!isValidPhoneNumber(normalized)) {
      return 'Enter a valid phone number with country code, for example +60120000101.';
    }
    _pendingPhone = normalized;
    return null;
  }

  @override
  Future<AuthOperation> verifyPhoneOtp(
      {required String phone, required String token}) async {
    final normalized = normalizePhoneNumber(phone);
    if (!isValidPhoneNumber(normalized)) {
      return const AuthOperation(
          error: 'Enter a valid phone number with country code.');
    }
    if (_pendingPhone != normalized) {
      return const AuthOperation(
          error: 'Request a new verification code first.');
    }
    if (token.trim() != '123456') {
      return const AuthOperation(error: 'That verification code is not valid.');
    }
    _registeredFullName = null;
    _user =
        AuthUser(id: 'demo-phone-$normalized', email: '', phone: normalized);
    return AuthOperation(user: _user);
  }

  @override
  Future<String?> resetPassword(String email) async =>
      email.trim().isEmpty ? 'Enter your email address.' : null;

  @override
  Future<String?> signOut() async {
    _user = null;
    _registeredFullName = null;
    _pendingPhone = null;
    return null;
  }

  static String _fakeUserId(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized == 'demo@ofrivo.local') return 'demo-user';
    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return safe.isEmpty ? 'demo-user' : 'demo-user-$safe';
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);

  final SupabaseClient client;

  @override
  bool get isDemoMode => false;

  AuthUser? _toAuthUser(User? user) => user == null
      ? null
      : AuthUser(id: user.id, email: user.email ?? '', phone: user.phone);

  @override
  Future<AuthUser?> restoreSession() async =>
      _toAuthUser(client.auth.currentUser);

  @override
  Future<ProfileData?> ensureProfile(AuthUser user) async {
    final existing = await client
        .from('profiles')
        .select('*, provider_profiles(verification_status)')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return ProfileData.fromMap(existing, id: user.id);

    final identity = user.email.isNotEmpty
        ? user.email.split('@').first
        : (user.phone ?? 'Ofrivo member');
    final created = await client
        .from('profiles')
        .insert({
          'id': user.id,
          'full_name': identity,
          'display_name': identity,
          if (user.phone != null) 'phone': user.phone
        })
        .select('*, provider_profiles(verification_status)')
        .single();
    return ProfileData.fromMap(created, id: user.id);
  }

  @override
  Future<AuthOperation> signIn(
      {required String email, required String password}) async {
    try {
      final response = await client.auth
          .signInWithPassword(email: email.trim(), password: password);
      return AuthOperation(user: _toAuthUser(response.user));
    } on AuthException catch (error) {
      return AuthOperation(error: error.message);
    } catch (_) {
      return const AuthOperation(
          error: 'Unable to sign in. Check your connection and try again.');
    }
  }

  @override
  Future<AuthOperation> register(
      {required String fullName,
      required String email,
      required String password}) async {
    try {
      final response = await client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()});
      final user = _toAuthUser(response.user);
      return AuthOperation(
          user: user,
          needsEmailConfirmation: user != null && response.session == null);
    } on AuthException catch (error) {
      return AuthOperation(error: error.message);
    } catch (_) {
      return const AuthOperation(
          error:
              'Unable to create the account. Check your connection and try again.');
    }
  }

  @override
  Future<String?> requestPhoneOtp(String phone) async {
    final normalized = normalizePhoneNumber(phone);
    if (!isValidPhoneNumber(normalized)) {
      return 'Enter a valid phone number with country code, for example +60120000101.';
    }
    try {
      await client.auth.signInWithOtp(phone: normalized);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to send the verification code. Check your connection and try again.';
    }
  }

  @override
  Future<AuthOperation> verifyPhoneOtp(
      {required String phone, required String token}) async {
    final normalized = normalizePhoneNumber(phone);
    if (!isValidPhoneNumber(normalized)) {
      return const AuthOperation(
          error: 'Enter a valid phone number with country code.');
    }
    if (token.trim().length != 6) {
      return const AuthOperation(error: 'Enter the 6-digit verification code.');
    }
    try {
      final response = await client.auth
          .verifyOTP(phone: normalized, token: token.trim(), type: OtpType.sms);
      return AuthOperation(user: _toAuthUser(response.user));
    } on AuthException catch (error) {
      return AuthOperation(error: error.message);
    } catch (_) {
      return const AuthOperation(
          error:
              'Unable to verify the code. Check your connection and try again.');
    }
  }

  @override
  Future<String?> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to send reset instructions. Try again later.';
    }
  }

  @override
  Future<String?> signOut() async {
    try {
      await client.auth.signOut();
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to sign out. Try again.';
    }
  }
}
