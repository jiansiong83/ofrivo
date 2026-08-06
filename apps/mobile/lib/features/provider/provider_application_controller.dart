import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/models/service_options.dart';
import '../auth/auth_controller.dart';
import 'provider_application_models.dart';
import 'provider_application_repository.dart';

final providerApplicationRepositoryProvider =
    Provider<ProviderApplicationRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    return FakeProviderApplicationRepository(
        initialStatus: providerApplicationStatusFromValue(
            auth.profile?.providerVerificationStatus));
  }
  return SupabaseProviderApplicationRepository(client, auth.user!.id);
});

final providerApplicationControllerProvider = StateNotifierProvider<
    ProviderApplicationController, ProviderApplicationState>((ref) {
  final controller = ProviderApplicationController(
      ref.watch(providerApplicationRepositoryProvider));
  controller.load();
  return controller;
});

class ProviderApplicationState {
  const ProviderApplicationState(
      {this.initialized = false,
      this.isLoading = false,
      this.application,
      this.error,
      this.info});

  final bool initialized;
  final bool isLoading;
  final ProviderApplication? application;
  final String? error;
  final String? info;

  ProviderApplicationStatus get status =>
      application?.status ?? ProviderApplicationStatus.notApplied;

  ProviderApplicationState copyWith(
          {bool? initialized,
          bool? isLoading,
          ProviderApplication? application,
          String? error,
          String? info,
          bool clearApplication = false,
          bool clearError = false,
          bool clearInfo = false}) =>
      ProviderApplicationState(
        initialized: initialized ?? this.initialized,
        isLoading: isLoading ?? this.isLoading,
        application: clearApplication ? null : application ?? this.application,
        error: clearError ? null : error ?? this.error,
        info: clearInfo ? null : info ?? this.info,
      );
}

class ProviderApplicationController
    extends StateNotifier<ProviderApplicationState> {
  ProviderApplicationController(this.repository)
      : super(const ProviderApplicationState());

  final ProviderApplicationRepository repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.load();
      state =
          ProviderApplicationState(initialized: true, application: application);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error:
              'Unable to load your provider application. Check your connection.');
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
      state = ProviderApplicationState(
          initialized: true,
          application: application,
          info: 'Application submitted for review.');
      return application;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }

  Future<ProviderApplication?> updateProfile({
    required String displayName,
    required String bio,
    required String phone,
    required String whatsapp,
    required List<ServiceAreaOption> areas,
    required List<String> workPhotoPaths,
  }) async {
    if (displayName.trim().length < 2) {
      state = state.copyWith(
          error: 'Add a business or display name.', clearInfo: true);
      return null;
    }
    if (bio.trim().length < 10) {
      state = state.copyWith(
          error: 'Tell customers a little more about your work.',
          clearInfo: true);
      return null;
    }
    if (areas.isEmpty) {
      state = state.copyWith(
          error: 'Choose at least one service area.', clearInfo: true);
      return null;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.updateProfile(
        displayName: displayName,
        bio: bio,
        phone: phone,
        whatsapp: whatsapp,
        areas: areas,
        workPhotoPaths: workPhotoPaths,
      );
      state = ProviderApplicationState(
          initialized: true,
          application: application,
          info: 'Provider profile updated.');
      return application;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }

  Future<ProviderApplication?> submitCategoryChanges(
      List<ServiceCategoryOption> categories) async {
    if (categories.isEmpty) {
      state = state.copyWith(
          error: 'Choose at least one service category.', clearInfo: true);
      return null;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.submitCategoryChanges(categories);
      state = ProviderApplicationState(
          initialized: true,
          application: application,
          info: 'Category changes sent for review.');
      return application;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }

  Future<ProviderApplication?> setAvailability(bool isAvailable) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final application = await repository.setAvailability(isAvailable);
      state = ProviderApplicationState(
          initialized: true,
          application: application,
          info: isAvailable
              ? 'You are available for new jobs.'
              : 'You are hidden from new jobs.');
      return application;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }
}
