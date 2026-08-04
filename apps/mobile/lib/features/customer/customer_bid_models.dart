import '../../core/models/app_models.dart';

class CustomerBidOffer {
  const CustomerBidOffer({required this.bid, required this.provider});

  final Bid bid;
  final ProviderProfile provider;
}

class BidAcceptance {
  const BidAcceptance(
      {required this.jobId,
      required this.bidId,
      required this.providerId,
      this.jobStatus = JobStatus.assigned});

  final String jobId;
  final String bidId;
  final String providerId;
  final JobStatus jobStatus;
}

class CustomerBidState {
  const CustomerBidState({
    this.initialized = false,
    this.isLoading = false,
    this.isAccepting = false,
    this.bids = const [],
    this.error,
    this.info,
  });

  final bool initialized;
  final bool isLoading;
  final bool isAccepting;
  final List<CustomerBidOffer> bids;
  final String? error;
  final String? info;

  CustomerBidState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isAccepting,
    List<CustomerBidOffer>? bids,
    String? error,
    String? info,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return CustomerBidState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isAccepting: isAccepting ?? this.isAccepting,
      bids: bids ?? this.bids,
      error: clearError ? null : error ?? this.error,
      info: clearInfo ? null : info ?? this.info,
    );
  }
}
