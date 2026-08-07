import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/fake_data.dart';
import '../../core/models/app_models.dart';
import 'customer_bid_models.dart';

abstract interface class CustomerBidRepository {
  Future<List<CustomerBidOffer>> loadReceivedBids(String jobId);

  Future<ProviderProfile?> loadProviderProfile(String providerId);

  Future<BidAcceptance> acceptBid(
      {required String jobId, required String bidId});
}

class FakeCustomerBidRepository implements CustomerBidRepository {
  FakeCustomerBidRepository(
      {required List<Job> initialJobs,
      required List<Bid> initialBids,
      List<ProviderProfile>? profiles,
      String userId = 'demo-user'})
      : userId = userId,
        _jobs = fakeJobsForCustomer(userId, initialJobs),
        _bids = fakeBidsForJobs(
            fakeJobsForCustomer(userId, initialJobs), initialBids),
        _profiles = {
          for (final profile in profiles ?? fakeProviderProfiles)
            if (profile.id != null) profile.id!: profile
        };

  final String userId;
  final List<Job> _jobs;
  final List<Bid> _bids;
  final Map<String, ProviderProfile> _profiles;

  @override
  Future<List<CustomerBidOffer>> loadReceivedBids(String jobId) async {
    if (!_jobs.any((job) => job.id == jobId)) return const [];
    final offers = _bids.where((bid) => bid.jobId == jobId).toList()
      ..sort((left, right) {
        final statusOrder =
            _statusWeight(left.status).compareTo(_statusWeight(right.status));
        if (statusOrder != 0) return statusOrder;
        return (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
                left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
    return List<CustomerBidOffer>.unmodifiable(offers.map(
        (bid) => CustomerBidOffer(bid: bid, provider: _profileForBid(bid))));
  }

  @override
  Future<ProviderProfile?> loadProviderProfile(String providerId) async =>
      _profiles[providerId];

  @override
  Future<BidAcceptance> acceptBid(
      {required String jobId, required String bidId}) async {
    final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
    if (jobIndex < 0) throw StateError('Job not found.');
    final job = _jobs[jobIndex];
    if (job.status != JobStatus.open) {
      throw StateError('Only an open job can accept an offer.');
    }

    final bidIndex =
        _bids.indexWhere((bid) => bid.id == bidId && bid.jobId == jobId);
    if (bidIndex < 0) throw StateError('Offer not found.');
    final target = _bids[bidIndex];
    if (target.status != BidStatus.pending) {
      throw StateError('This offer is no longer pending.');
    }
    final providerId = target.providerId;
    if (providerId == null || !_profiles.containsKey(providerId)) {
      throw StateError('The provider profile is no longer available.');
    }

    for (var index = 0; index < _bids.length; index++) {
      final bid = _bids[index];
      if (bid.jobId != jobId || bid.status != BidStatus.pending) continue;
      _bids[index] = bid.copyWith(
          status: bid.id == bidId ? BidStatus.accepted : BidStatus.rejected);
    }
    _jobs[jobIndex] =
        job.copyWith(status: JobStatus.assigned, acceptedBidId: bidId);

    final notificationId =
        'local-notification-${DateTime.now().microsecondsSinceEpoch}';
    fakeNotifications.insert(
      0,
      AppNotification(
        id: notificationId,
        type: NotificationType.jobAssigned,
        title: 'Provider selected',
        body:
            'Your job is now assigned. The selected provider can see the service address and contact details.',
        isRead: false,
        createdAt: DateTime.now(),
        referenceType: 'job',
        referenceId: jobId,
        recipientId: userId,
      ),
    );
    return BidAcceptance(jobId: jobId, bidId: bidId, providerId: providerId);
  }

  ProviderProfile _profileForBid(Bid bid) {
    final profile = bid.providerId == null ? null : _profiles[bid.providerId];
    return profile ??
        ProviderProfile(
          id: bid.providerId,
          name: bid.providerName,
          category: bid.providerCategory,
          area: 'Johor Bahru',
          rating: bid.rating,
          completedJobs: bid.completedJobs,
          bio: 'Verified local service provider.',
          verification: bid.verified
              ? VerificationStatus.approved
              : VerificationStatus.pending,
        );
  }

  static int _statusWeight(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return 0;
      case BidStatus.pending:
        return 1;
      case BidStatus.rejected:
        return 2;
      case BidStatus.withdrawn:
        return 3;
      case BidStatus.expired:
        return 4;
    }
  }
}

class SupabaseCustomerBidRepository implements CustomerBidRepository {
  SupabaseCustomerBidRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<CustomerBidOffer>> loadReceivedBids(String jobId) async {
    final rows = await client
        .from('bids')
        .select('*, jobs!inner(customer_id)')
        .eq('job_id', jobId)
        .eq('jobs.customer_id', userId)
        .order('created_at', ascending: false);
    final offers = <CustomerBidOffer>[];
    for (final raw in (rows as List).whereType<Map<String, dynamic>>()) {
      final bid = _mapBid(raw);
      final profile = await loadProviderProfile(bid.providerId ?? '');
      offers.add(CustomerBidOffer(
          bid: _withProviderDetails(bid, profile),
          provider: profile ?? _fallbackProfile(bid)));
    }
    offers.sort((left, right) => _statusWeight(left.bid.status)
        .compareTo(_statusWeight(right.bid.status)));
    return List<CustomerBidOffer>.unmodifiable(offers);
  }

  @override
  Future<ProviderProfile?> loadProviderProfile(String providerId) async {
    if (providerId.trim().isEmpty) return null;
    final row = await client
        .from('public_provider_directory')
        .select()
        .eq('id', providerId)
        .maybeSingle();
    if (row == null) return null;
    final value = Map<String, dynamic>.from(row);
    final portfolioUrls = await _loadPortfolioUrls(providerId);
    return ProviderProfile(
      id: value['id'] as String? ?? providerId,
      name: value['display_name'] as String? ?? 'Verified provider',
      category: 'Verified local provider',
      area: 'Johor Bahru',
      rating: (value['rating_average'] as num?)?.toDouble() ?? 0,
      completedJobs: (value['completed_jobs'] as num?)?.toInt() ?? 0,
      bio: value['bio'] as String? ?? 'Verified local service provider.',
      verification: VerificationStatus.approved,
      avatarPath: value['avatar_path'] as String?,
      portfolioUrls: portfolioUrls,
      isAvailable: value['is_available'] as bool? ?? true,
    );
  }

  Future<List<String>> _loadPortfolioUrls(String providerId) async {
    try {
      final row = await client
          .from('public_provider_portfolio')
          .select('photo_paths')
          .eq('provider_id', providerId)
          .maybeSingle();
      final paths = row?['photo_paths'];
      if (paths is! List) return const [];
      return [
        for (final path in paths.whereType<String>())
          client.storage.from('provider-portfolio').getPublicUrl(path),
      ];
    } catch (_) {
      // A profile remains usable while a hosted project rolls out the view.
      return const [];
    }
  }

  @override
  Future<BidAcceptance> acceptBid(
      {required String jobId, required String bidId}) async {
    final raw = await client
        .rpc('accept_bid', params: {'p_job_id': jobId, 'p_bid_id': bidId});
    final value =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final providerId = value['provider_id'] as String?;
    if (providerId == null) {
      throw StateError('The server did not return the selected provider.');
    }
    return BidAcceptance(
      jobId: value['job_id'] as String? ?? jobId,
      bidId: value['bid_id'] as String? ?? bidId,
      providerId: providerId,
      jobStatus: _jobStatus(value['job_status'] as String?),
    );
  }

  Bid _mapBid(Map<String, dynamic> row) {
    final availableAt = _parseDate(row['available_at']);
    final statusValue = row['status'] as String? ?? 'pending';
    return Bid(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      providerName: 'Verified provider',
      providerCategory: 'Verified local provider',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      availableAt: availableAt == null ? 'Flexible' : _displayDate(availableAt),
      inclusions: row['inclusions'] as String? ?? '',
      exclusions: row['exclusions'] as String? ?? '',
      status: BidStatus.values.firstWhere((item) => item.name == statusValue,
          orElse: () => BidStatus.pending),
      rating: 0,
      completedJobs: 0,
      providerId: row['provider_id'] as String?,
      materialsNote: row['materials_note'] as String?,
      message: row['message'] as String?,
      availableAtDate: availableAt,
      createdAt: _parseDate(row['created_at']),
    );
  }

  Bid _withProviderDetails(Bid bid, ProviderProfile? profile) => profile == null
      ? bid
      : bid.copyWith(
          providerName: profile.name,
          providerCategory: profile.category,
          rating: profile.rating,
          completedJobs: profile.completedJobs,
          verified: profile.verification == VerificationStatus.approved);

  ProviderProfile _fallbackProfile(Bid bid) => ProviderProfile(
        id: bid.providerId,
        name: bid.providerName,
        category: bid.providerCategory,
        area: 'Johor Bahru',
        rating: bid.rating,
        completedJobs: bid.completedJobs,
        bio: 'Verified local service provider.',
        verification: bid.verified
            ? VerificationStatus.approved
            : VerificationStatus.pending,
      );

  static int _statusWeight(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return 0;
      case BidStatus.pending:
        return 1;
      case BidStatus.rejected:
        return 2;
      case BidStatus.withdrawn:
        return 3;
      case BidStatus.expired:
        return 4;
    }
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static String _displayDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}, ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')}${date.hour >= 12 ? 'pm' : 'am'}';

  static JobStatus _jobStatus(String? value) => JobStatus.values.firstWhere(
      (item) =>
          item.name == value ||
          (item == JobStatus.inProgress && value == 'in_progress'),
      orElse: () => JobStatus.assigned);
}
