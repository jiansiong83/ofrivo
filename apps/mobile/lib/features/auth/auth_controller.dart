import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = AppBootstrap.client;
  return client == null ? FakeAuthRepository() : SupabaseAuthRepository(client);
});

class AuthState {
  const AuthState({
    this.initialized = false,
    this.isLoading = false,
    this.user,
    this.profile,
    this.error,
    this.info,
  });

  final bool initialized;
  final bool isLoading;
  final AuthUser? user;
  final ProfileData? profile;
  final String? error;
  final String? info;

  bool get isAuthenticated => user != null;
  bool get isSuspended => profile?.isSuspended ?? false;
  bool get isApprovedProvider => profile?.isApprovedProvider ?? false;

  AuthState copyWith({
    bool? initialized,
    bool? isLoading,
    AuthUser? user,
    ProfileData? profile,
    String? error,
    String? info,
    bool clearUser = false,
    bool clearProfile = false,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      profile: clearProfile ? null : profile ?? this.profile,
      error: clearError ? null : error ?? this.error,
      info: clearInfo ? null : info ?? this.info,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  controller.restoreSession();
  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.repository) : super(const AuthState());

  final AuthRepository repository;

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final user = await repository.restoreSession();
      if (user == null) {
        state = state.copyWith(
            initialized: true,
            isLoading: false,
            clearUser: true,
            clearProfile: true);
        return;
      }
      final profile = await repository.ensureProfile(user);
      state = AuthState(initialized: true, user: user, profile: profile);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to restore your session. Check your connection.');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final result = await repository.signIn(email: email, password: password);
    if (!result.succeeded) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: result.error ?? 'Unable to sign in.');
      return false;
    }
    final profile = await repository.ensureProfile(result.user!);
    state = AuthState(
        initialized: true,
        user: result.user,
        profile: profile,
        info: result.needsEmailConfirmation
            ? 'Check your email to confirm the account.'
            : null);
    return true;
  }

  Future<bool> register(
      {required String fullName,
      required String email,
      required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final result = await repository.register(
        fullName: fullName, email: email, password: password);
    if (!result.succeeded) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: result.error ?? 'Unable to register.');
      return false;
    }
    if (result.user == null || result.needsEmailConfirmation) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          info: 'Check your email to confirm the account.',
          clearUser: true,
          clearProfile: true);
      return false;
    }
    final profile = await repository.ensureProfile(result.user!);
    state = AuthState(
        initialized: true,
        user: result.user,
        profile: profile,
        info: result.needsEmailConfirmation
            ? 'Check your email to confirm the account.'
            : null);
    return true;
  }

  Future<String?> requestPhoneOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final error = await repository.requestPhoneOtp(phone);
    state = state.copyWith(
        isLoading: false,
        error: error,
        info: error == null ? 'Verification code sent.' : null);
    return error;
  }

  Future<bool> verifyPhoneOtp(
      {required String phone, required String token}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final result = await repository.verifyPhoneOtp(phone: phone, token: token);
    if (!result.succeeded) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: result.error ?? 'Unable to verify the code.');
      return false;
    }
    final profile = await repository.ensureProfile(result.user!);
    state = AuthState(initialized: true, user: result.user, profile: profile);
    return true;
  }

  Future<String?> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final error = await repository.resetPassword(email);
    state = state.copyWith(
        isLoading: false,
        error: error,
        info: error == null ? 'Reset instructions sent.' : null);
    return error;
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    final error = await repository.signOut();
    state = AuthState(initialized: true, error: error);
  }
}
