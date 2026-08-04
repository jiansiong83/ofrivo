import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'device_token_repository.dart';
import 'device_token_source.dart';

final deviceTokenSourceProvider = Provider<DeviceTokenSource>((ref) {
  return AppBootstrap.demoMode
      ? const DemoDeviceTokenSource()
      : const RuntimeDeviceTokenSource();
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  final client = AppBootstrap.client;
  if (client == null) {
    return FakeDeviceTokenRepository();
  }
  return SupabaseDeviceTokenRepository(client);
});

final pushRegistrationControllerProvider =
    StateNotifierProvider<PushRegistrationController, PushRegistrationState>(
        (ref) {
  final controller = PushRegistrationController(
    repository: ref.watch(deviceTokenRepositoryProvider),
    source: ref.watch(deviceTokenSourceProvider),
    platform: AppConfig.pushPlatform,
  );
  controller.register();
  return controller;
});

class PushRegistrationState {
  const PushRegistrationState({
    this.initialized = false,
    this.isRegistering = false,
    this.tokenRegistered = false,
    this.token,
    this.error,
  });

  final bool initialized;
  final bool isRegistering;
  final bool tokenRegistered;
  final String? token;
  final String? error;

  PushRegistrationState copyWith({
    bool? initialized,
    bool? isRegistering,
    bool? tokenRegistered,
    String? token,
    String? error,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return PushRegistrationState(
      initialized: initialized ?? this.initialized,
      isRegistering: isRegistering ?? this.isRegistering,
      tokenRegistered: tokenRegistered ?? this.tokenRegistered,
      token: clearToken ? null : token ?? this.token,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PushRegistrationController
    extends StateNotifier<PushRegistrationState> {
  PushRegistrationController({
    required this.repository,
    required this.source,
    required this.platform,
  }) : super(const PushRegistrationState());

  final DeviceTokenRepository repository;
  final DeviceTokenSource source;
  final String platform;
  StreamSubscription<String>? _refreshSubscription;

  Future<void> register() async {
    if (state.isRegistering || state.tokenRegistered) return;
    state = state.copyWith(
        isRegistering: true, initialized: false, clearError: true);
    try {
      final token = await source.readToken();
      if (token == null || token.trim().isEmpty) {
        state = state.copyWith(
            initialized: true, isRegistering: false, clearError: true);
        return;
      }
      await _registerToken(token);
      _refreshSubscription ??= source.tokenRefreshes.listen(_registerToken);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isRegistering: false,
          error: 'Push notifications are not available right now.');
    }
  }

  Future<void> unregister() async {
    final token = state.token;
    if (token == null || token.isEmpty) return;
    try {
      await repository.unregister(token: token);
    } finally {
      state = state.copyWith(
          initialized: true,
          isRegistering: false,
          tokenRegistered: false,
          clearToken: true);
    }
  }

  Future<void> _registerToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(isRegistering: true, clearError: true);
    await repository.register(token: normalized, platform: platform);
    state = state.copyWith(
        initialized: true,
        isRegistering: false,
        tokenRegistered: true,
        token: normalized,
        clearError: true);
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }
}
