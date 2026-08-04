import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../auth/auth_controller.dart';
import 'provider_job_models.dart';
import 'provider_job_repository.dart';

final providerJobRepositoryProvider = Provider<ProviderJobRepository>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = AppBootstrap.client;
  if (client == null || auth.user == null) {
    final profile = ref.watch(providerProfileProvider);
    return FakeProviderJobRepository(
      initialJobs: ref.watch(fakeJobsProvider),
      initialBids: ref.watch(fakeBidsProvider),
      providerId: auth.user?.id ?? 'demo-user',
      providerName: profile.name,
    );
  }
  return SupabaseProviderJobRepository(client, auth.user!.id);
});

final providerJobControllerProvider =
    StateNotifierProvider<ProviderJobController, ProviderJobState>((ref) {
  final controller =
      ProviderJobController(ref.watch(providerJobRepositoryProvider));
  controller.loadFeed();
  controller.loadMyBids();
  controller.loadAssignedJobs();
  return controller;
});

class ProviderJobController extends StateNotifier<ProviderJobState> {
  ProviderJobController(this.repository) : super(const ProviderJobState());

  final ProviderJobRepository repository;

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobs = await repository.loadFeed(filters: state.filters);
      state = state.copyWith(initialized: true, isLoading: false, jobs: jobs);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to load the job feed. Check your connection.');
    }
  }

  Future<void> loadMyBids() async {
    try {
      final bids = await repository.loadMyBids();
      state = state.copyWith(myBids: bids);
    } catch (_) {
      state = state.copyWith(
          error: 'Unable to load your bids. Check your connection.');
    }
  }

  Future<void> loadAssignedJobs() async {
    try {
      final jobs = await repository.loadAssignedJobs();
      state = state.copyWith(assignedJobs: jobs);
    } catch (_) {
      state = state.copyWith(
          error: 'Unable to load assigned jobs. Check your connection.');
    }
  }

  Future<Job?> loadAssignedJob(String jobId) async {
    for (final job in state.assignedJobs) {
      if (job.id == jobId) return job;
    }
    final loaded = await repository.loadAssignedJob(jobId);
    if (loaded != null) {
      state = state.copyWith(assignedJobs: [
        loaded,
        ...state.assignedJobs.where((job) => job.id != loaded.id)
      ]);
    }
    return loaded;
  }

  Future<void> setFilters(ProviderJobFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadFeed();
  }

  Future<void> clearFilters() async => setFilters(const ProviderJobFilters());

  Future<ProviderBid?> myBidForJob(String jobId) async {
    for (final providerBid in state.myBids) {
      if (providerBid.bid.jobId == jobId &&
          (providerBid.bid.status == BidStatus.pending ||
              providerBid.bid.status == BidStatus.accepted)) {
        return providerBid;
      }
    }
    final loaded = await repository.loadMyBidForJob(jobId);
    if (loaded != null) {
      final bids = [
        loaded,
        ...state.myBids.where((item) => item.bid.id != loaded.bid.id)
      ];
      state = state.copyWith(myBids: bids);
    }
    return loaded;
  }

  Future<ProviderBid?> submitBid(BidDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final saved = await repository.saveBid(draft);
      final bids = [
        saved,
        ...state.myBids.where((item) => item.bid.id != saved.bid.id)
      ];
      state = state.copyWith(isSubmitting: false, myBids: bids);
      await loadFeed();
      return saved;
    } catch (error) {
      state = state.copyWith(
          isSubmitting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return null;
    }
  }

  Future<bool> withdrawBid(String bidId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await repository.withdrawBid(bidId);
      state = state.copyWith(
        isSubmitting: false,
        myBids: [
          for (final item in state.myBids)
            if (item.bid.id == bidId)
              ProviderBid(
                  bid: item.bid.copyWith(status: BidStatus.withdrawn),
                  job: item.job)
            else
              item,
        ],
      );
      await loadFeed();
      return true;
    } catch (error) {
      state = state.copyWith(
          isSubmitting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }
}
