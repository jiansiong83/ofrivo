import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../auth/auth_controller.dart';
import '../customer/customer_jobs_controller.dart';
import '../provider/provider_job_controller.dart';
import 'job_lifecycle_models.dart';
import 'job_lifecycle_repository.dart';

final jobLifecycleRepositoryProvider = Provider<JobLifecycleRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    return FakeJobLifecycleRepository(
        initialJobs: ref.watch(fakeJobsProvider),
        initialBids: ref.watch(fakeBidsProvider),
        role: ref.watch(appModeProvider),
        providerId: auth.user?.id ?? 'demo-user');
  }
  return SupabaseJobLifecycleRepository(client, auth.user!.id);
});

final jobLifecycleControllerProvider = StateNotifierProvider.family<
    JobLifecycleController, JobLifecycleState, String>((ref, jobId) {
  final controller = JobLifecycleController(
      ref.watch(jobLifecycleRepositoryProvider),
      jobId: jobId, onStatusChanged: (transition) {
    ref
        .read(customerJobsControllerProvider.notifier)
        .applyJobUpdate(transition.jobId, transition.status, null);
    ref
        .read(providerJobControllerProvider.notifier)
        .applyAssignedJobUpdate(transition.jobId, transition.status);
  });
  controller.load();
  return controller;
});

class JobLifecycleController extends StateNotifier<JobLifecycleState> {
  JobLifecycleController(this.repository,
      {required this.jobId, this.onStatusChanged})
      : super(const JobLifecycleState());

  final JobLifecycleRepository repository;
  final String jobId;
  final void Function(JobTransition transition)? onStatusChanged;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait(
          [repository.loadEvents(jobId), repository.loadReviews(jobId)]);
      state = JobLifecycleState(
          initialized: true,
          events: results[0] as List<JobEventRecord>,
          reviews: results[1] as List<ReviewRecord>);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to load job history. Check your connection.');
    }
  }

  Future<bool> start(String jobId) =>
      _transition(jobId, repository.startJob, 'Job started.');

  Future<bool> complete(String jobId) =>
      _transition(jobId, repository.completeJob, 'Job completed.');

  Future<bool> cancel(String jobId, {String? reason}) => _transition(jobId,
      (id) => repository.cancelJob(id, reason: reason), 'Job cancelled.');

  Future<bool> _transition(
      String jobId,
      Future<JobTransition> Function(String) action,
      String successMessage) async {
    state =
        state.copyWith(isSubmitting: true, clearError: true, clearInfo: true);
    try {
      final result = await action(jobId);
      onStatusChanged?.call(result);
      final events = await repository.loadEvents(jobId);
      state = state.copyWith(
          isSubmitting: false,
          initialized: true,
          status: result.status,
          events: events,
          info: successMessage);
      return true;
    } catch (error) {
      state = state.copyWith(
          isSubmitting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }

  Future<bool> submitReview(String jobId, ReviewDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }
    state =
        state.copyWith(isSubmitting: true, clearError: true, clearInfo: true);
    try {
      final review = await repository.submitReview(jobId: jobId, draft: draft);
      state = state.copyWith(
          isSubmitting: false,
          reviews: [review, ...state.reviews],
          info: 'Review submitted. Thank you.');
      return true;
    } catch (error) {
      state = state.copyWith(
          isSubmitting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }

  Future<bool> submitReport(String jobId, ReportDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }
    state =
        state.copyWith(isSubmitting: true, clearError: true, clearInfo: true);
    try {
      await repository.submitReport(jobId: jobId, draft: draft);
      state = state.copyWith(
          isSubmitting: false,
          info: 'Report submitted to the Ofrivo safety team.');
      return true;
    } catch (error) {
      state = state.copyWith(
          isSubmitting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }
}
