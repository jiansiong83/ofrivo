import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'auth_models.dart';

abstract interface class AuthRepository {
  bool get isDemoMode;
  Future<AuthUser?> restoreSession();
  Future<ProfileData?> ensureProfile(AuthUser user);
  Future<AuthOperation> signIn({required String email, required String password});
  Future<AuthOperation> register({required String fullName, required String email, required String password});
  Future<String?> resetPassword(String email);
  Future<String?> signOut();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository()
      : _user = const AuthUser(id: 'demo-user', email: 'demo@ofrivo.local'),
        _profile = const ProfileData(
          id: 'demo-user',
          fullName: 'Alex Tan',
          displayName: 'Alex',
          phone: '+60 12 000 0101',
          whatsapp: '+60 12 000 0101',
          accountStatus: 'active',
          isAdmin: false,
          providerVerificationStatus: 'approved',
        );

  AuthUser? _user;
  final ProfileData _profile;

  @override
  bool get isDemoMode => true;

  @override
  Future<AuthUser?> restoreSession() async => _user;

  @override
  Future<ProfileData?> ensureProfile(AuthUser user) async => _profile;

  @override
  Future<AuthOperation> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthOperation(error: 'Enter your email and password.');
    }
    _user = AuthUser(id: 'demo-user', email: email.trim());
    return AuthOperation(user: _user);
  }

  @override
  Future<AuthOperation> register({required String fullName, required String email, required String password}) async {
    if (fullName.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      return const AuthOperation(error: 'Use a name, a valid email, and a password of at least 6 characters.');
    }
    _user = AuthUser(id: 'demo-user', email: email.trim());
    return AuthOperation(user: _user);
  }

  @override
  Future<String?> resetPassword(String email) async => email.trim().isEmpty ? 'Enter your email address.' : null;

  @override
  Future<String?> signOut() async {
    _user = null;
    return null;
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);

  final SupabaseClient client;

  @override
  bool get isDemoMode => false;

  AuthUser? _toAuthUser(User? user) => user == null ? null : AuthUser(id: user.id, email: user.email ?? '');

  @override
  Future<AuthUser?> restoreSession() async => _toAuthUser(client.auth.currentUser);

  @override
  Future<ProfileData?> ensureProfile(AuthUser user) async {
    final existing = await client.from('profiles').select('*, provider_profiles(verification_status)').eq('id', user.id).maybeSingle();
    if (existing != null) return ProfileData.fromMap(existing, id: user.id);

    final created = await client.from('profiles').insert({'id': user.id, 'full_name': user.email.split('@').first, 'display_name': user.email.split('@').first}).select('*, provider_profiles(verification_status)').single();
    return ProfileData.fromMap(created, id: user.id);
  }

  @override
  Future<AuthOperation> signIn({required String email, required String password}) async {
    try {
      final response = await client.auth.signInWithPassword(email: email.trim(), password: password);
      return AuthOperation(user: _toAuthUser(response.user));
    } on AuthException catch (error) {
      return AuthOperation(error: error.message);
    } catch (_) {
      return const AuthOperation(error: 'Unable to sign in. Check your connection and try again.');
    }
  }

  @override
  Future<AuthOperation> register({required String fullName, required String email, required String password}) async {
    try {
      final response = await client.auth.signUp(email: email.trim(), password: password, data: {'full_name': fullName.trim()});
      final user = _toAuthUser(response.user);
      return AuthOperation(user: user, needsEmailConfirmation: user != null && response.session == null);
    } on AuthException catch (error) {
      return AuthOperation(error: error.message);
    } catch (_) {
      return const AuthOperation(error: 'Unable to create the account. Check your connection and try again.');
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
