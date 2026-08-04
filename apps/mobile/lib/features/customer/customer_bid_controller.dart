import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'customer_bid_models.dart';
import 'customer_bid_repository.dart';
import 'customer_jobs_controller.dart';

final customerBidRepositoryProvider = Provider<CustomerBidRepository>((ref) {
  final client = AppBootstrap.client;
  if (client == null) {
    return FakeCustomerBidRepository(
        initialJobs: ref.watch(fakeJobsProvider),
        initialBids: ref.watch(fakeBidsProvider));
  }
  return SupabaseCustomerBidRepository(client);
});

final customerBidControllerProvider = StateNotifierProvider.family<
    CustomerBidController, CustomerBidState, String>((ref, jobId) {
  final controller = CustomerBidController(
      ref.watch(customerBidRepositoryProvider), onJobUpdated: (result) {
    ref
        .read(customerJobsControllerProvider.notifier)
        .applyJobUpdate(result.jobId, result.jobStatus, result.bidId);
  });
  controller.load(jobId);
  return controller;
});

final customerProviderProfileProvider =
    FutureProvider.family<ProviderProfile?, String>((ref, providerId) => ref
        .read(customerBidRepositoryProvider)
        .loadProviderProfile(providerId));

class CustomerBidController extends StateNotifier<CustomerBidState> {
  CustomerBidController(this.repository, {this.onJobUpdated})
      : super(const CustomerBidState());

  final CustomerBidRepository repository;
  final void Function(BidAcceptance result)? onJobUpdated;

  Future<void> load(String jobId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final bids = await repository.loadReceivedBids(jobId);
      state = CustomerBidState(initialized: true, bids: bids);
    } catch (_) {
      state = state.copyWith(
          initialized: true,
          isLoading: false,
          error: 'Unable to load received offers. Check your connection.');
    }
  }

  Future<bool> accept(String jobId, String bidId) async {
    state =
        state.copyWith(isAccepting: true, clearError: true, clearInfo: true);
    try {
      final result = await repository.acceptBid(jobId: jobId, bidId: bidId);
      onJobUpdated?.call(result);
      final bids = await repository.loadReceivedBids(jobId);
      state = CustomerBidState(
          initialized: true,
          bids: bids,
          info:
              'Offer accepted. The provider can now see the service address.');
      return true;
    } catch (error) {
      state = state.copyWith(
          isAccepting: false,
          error: error.toString().replaceFirst('Bad state: ', ''));
      return false;
    }
  }
}
