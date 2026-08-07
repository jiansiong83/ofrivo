import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../auth/auth_controller.dart';
import 'customer_job_models.dart';
import 'customer_job_repository.dart';

final customerJobRepositoryProvider = Provider<CustomerJobRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    return FakeCustomerJobRepository(ref.watch(fakeJobsProvider),
        userId: auth.user?.id ?? '');
  }
  return SupabaseCustomerJobRepository(client, auth.user!.id);
});

final customerJobsControllerProvider =
    StateNotifierProvider<CustomerJobsController, CustomerJobsState>((ref) {
  final controller =
      CustomerJobsController(ref.watch(customerJobRepositoryProvider));
  controller.load();
  return controller;
});

class CustomerJobsController extends StateNotifier<CustomerJobsState> {
  CustomerJobsController(this.repository) : super(const CustomerJobsState());

  final CustomerJobRepository repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobs = await repository.loadMyJobs();
      state = CustomerJobsState(initialized: true, jobs: jobs);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to load your jobs. Check your connection.');
    }
  }

  Future<Job?> saveDraft(JobDraft draft) async => _save(draft, publish: false);

  Future<Job?> publish(JobDraft draft) async => _save(draft, publish: true);

  Future<Job?> _save(JobDraft draft, {required bool publish}) async {
    final validationError = draft.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return null;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final job = await repository.saveDraft(draft, publish: publish);
      final jobs = [job, ...state.jobs.where((item) => item.id != job.id)];
      state = CustomerJobsState(initialized: true, jobs: jobs);
      return job;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }

  Future<bool> cancel(String jobId, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.cancelJob(jobId, reason: reason);
      state = CustomerJobsState(initialized: true, jobs: [
        for (final job in state.jobs)
          if (job.id == jobId)
            job.copyWith(status: JobStatus.cancelled)
          else
            job
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }

  void applyJobUpdate(String jobId, JobStatus status, String? acceptedBidId) {
    state = state.copyWith(
      jobs: [
        for (final job in state.jobs)
          if (job.id == jobId)
            job.copyWith(status: status, acceptedBidId: acceptedBidId)
          else
            job,
      ],
      initialized: true,
      isLoading: false,
    );
  }
}
