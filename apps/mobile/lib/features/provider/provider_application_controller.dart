import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../auth/auth_controller.dart';
import 'provider_application_models.dart';
import 'provider_application_repository.dart';

final providerApplicationRepositoryProvider = Provider<ProviderApplicationRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    return FakeProviderApplicationRepository(initialStatus: providerApplicationStatusFromValue(auth.profile?.providerVerificationStatus));
  }
  return SupabaseProviderApplicationRepository(client, auth.user!.id);
});

final providerApplicationControllerProvider = StateNotifierProvider<ProviderApplicationController, ProviderApplicationState>((ref) {
  final controller = ProviderApplicationController(ref.watch(providerApplicationRepositoryProvider));
  controller.load();
  return controller;
});

class ProviderApplicationState {
  const ProviderApplicationState({this.initialized = false, this.isLoading = false, this.application, this.error, this.info});

  final bool initialized;
  final bool isLoading;
  final ProviderApplication? application;
  final String? error;
  final String? info;

  ProviderApplicationStatus get status => application?.status ?? ProviderApplicationStatus.notApplied;

  ProviderApplicationState copyWith({bool? initialized, bool? isLoading, ProviderApplication? application, String? error, String? info, bool clearApplication = false, bool clearError = false, bool clearInfo = false}) => ProviderApplicationState(
        initialized: initialized ?? this.initialized,
        isLoading: isLoading ?? this.isLoading,
        application: clearApplication ? null : application ?? this.application,
        error: clearError ? null : error ?? this.error,
        info: clearInfo ? null : info ?? this.info,
      );
}

class ProviderApplicationController extends StateNotifier<ProviderApplicationState> {
  ProviderApplicationController(this.repository) : super(const ProviderApplicationState());

  final ProviderApplicationRepository repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.load();
      state = ProviderApplicationState(initialized: true, application: application);
    } catch (_) {
      state = state.copyWith(initialized: true, isLoading: false, error: 'Unable to load your provider application. Check your connection.');
    }
  }

  Future<ProviderApplication?> submit(ProviderApplicationDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError, clearInfo: true);
      return null;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.submit(draft);
      state = ProviderApplicationState(initialized: true, application: application, info: 'Application submitted for review.');
      return application;
    } catch (error) {
      state = state.copyWith(initialized: true, isLoading: false, error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }
}
