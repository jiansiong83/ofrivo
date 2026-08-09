import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/app_models.dart';
import '../../core/models/service_options.dart';
import 'provider_job_models.dart';

abstract interface class ProviderJobRepository {
  Future<List<Job>> loadFeed({required ProviderJobFilters filters});

  Future<Job?> loadJob(String jobId);

  Future<List<ProviderBid>> loadMyBids();

  Future<ProviderBid?> loadMyBidForJob(String jobId);

  Future<ProviderBid> saveBid(BidDraft draft);

  Future<void> withdrawBid(String bidId);

  Future<List<Job>> loadAssignedJobs();

  Future<Job?> loadAssignedJob(String jobId);
}

class FakeProviderJobRepository implements ProviderJobRepository {
  FakeProviderJobRepository({
    required List<Job> initialJobs,
    required List<Bid> initialBids,
    this.providerId = 'demo-user',
    this.providerName = 'Ahmad Plumbing',
  })  : _jobs = List<Job>.from(initialJobs),
        _bids = List<Bid>.from(initialBids);

  final List<Job> _jobs;
  final List<Bid> _bids;
  final String providerId;
  final String providerName;
  var _sequence = 900;

  @override
  Future<List<Job>> loadFeed({required ProviderJobFilters filters}) async {
    return List<Job>.unmodifiable(filters
        .apply(_jobs.where((job) => job.status == JobStatus.open).toList()));
  }

  @override
  Future<Job?> loadJob(String jobId) async {
    for (final job in _jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  }

  @override
  Future<List<ProviderBid>> loadMyBids() async {
    return List<ProviderBid>.unmodifiable(
        _bids.where(_belongsToProvider).map(_toProviderBid));
  }

  @override
  Future<ProviderBid?> loadMyBidForJob(String jobId) async {
    for (final bid in _bids) {
      if (bid.jobId == jobId &&
          _belongsToProvider(bid) &&
          (bid.status == BidStatus.pending ||
              bid.status == BidStatus.accepted)) {
        return _toProviderBid(bid);
      }
    }
    return null;
  }

  @override
  Future<ProviderBid> saveBid(BidDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) throw StateError(validationError);
    final job = await loadJob(draft.jobId);
    if (job == null || job.status != JobStatus.open) {
      throw StateError('This job is no longer open for bids.');
    }

    final existingIndex = draft.bidId == null
        ? _bids.indexWhere((bid) =>
            bid.jobId == draft.jobId &&
            _belongsToProvider(bid) &&
            bid.status == BidStatus.pending)
        : _bids.indexWhere(
            (bid) => bid.id == draft.bidId && _belongsToProvider(bid));
    if (existingIndex >= 0) {
      final existing = _bids[existingIndex];
      if (existing.status != BidStatus.pending) {
        throw StateError('An accepted bid cannot be edited.');
      }
      final updated = existing.copyWith(
        amount: draft.amountValue,
        availableAt: _displayDate(draft.availableAt),
        availableAtDate: draft.availableAt,
        inclusions: draft.inclusions.trim(),
        exclusions: draft.exclusions.trim(),
        materialsNote: draft.materialsNote.trim(),
        message: draft.message.trim(),
      );
      _bids[existingIndex] = updated;
      return _toProviderBid(updated);
    }

    final created = Bid(
      id: 'local-bid-${_sequence++}',
      jobId: draft.jobId,
      providerName: providerName,
      providerCategory: 'Provider offer',
      amount: draft.amountValue!,
      availableAt: _displayDate(draft.availableAt),
      inclusions: draft.inclusions.trim(),
      exclusions: draft.exclusions.trim(),
      status: BidStatus.pending,
      rating: 4.9,
      completedJobs: 86,
      providerId: providerId,
      materialsNote: draft.materialsNote.trim(),
      message: draft.message.trim(),
      availableAtDate: draft.availableAt,
      createdAt: DateTime.now(),
    );
    _bids.add(created);
    _replaceJob(job.copyWith(bidCount: job.bidCount + 1));
    return _toProviderBid(created);
  }

  @override
  Future<void> withdrawBid(String bidId) async {
    final index =
        _bids.indexWhere((bid) => bid.id == bidId && _belongsToProvider(bid));
    if (index < 0) throw StateError('Bid not found.');
    final current = _bids[index];
    if (current.status != BidStatus.pending) {
      throw StateError('Only a pending bid can be withdrawn.');
    }
    _bids[index] = current.copyWith(status: BidStatus.withdrawn);
    final job = await loadJob(current.jobId);
    if (job != null) {
      _replaceJob(
          job.copyWith(bidCount: job.bidCount > 0 ? job.bidCount - 1 : 0));
    }
  }

  @override
  Future<List<Job>> loadAssignedJobs() async {
    final assigned = <Job>[];
    for (final job in _jobs) {
      if (job.status != JobStatus.assigned &&
          job.status != JobStatus.inProgress &&
          job.status != JobStatus.completed) {
        continue;
      }
      Bid? accepted;
      for (final bid in _bids) {
        if (bid.id == job.acceptedBidId && bid.status == BidStatus.accepted) {
          accepted = bid;
          break;
        }
      }
      if (accepted != null && _belongsToProvider(accepted)) assigned.add(job);
    }
    return List<Job>.unmodifiable(assigned);
  }

  @override
  Future<Job?> loadAssignedJob(String jobId) async {
    final jobs = await loadAssignedJobs();
    for (final job in jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  }

  bool _belongsToProvider(Bid bid) =>
      bid.providerId == providerId ||
      (bid.providerId == null && bid.providerName == providerName);

  ProviderBid _toProviderBid(Bid bid) {
    Job? job;
    for (final candidate in _jobs) {
      if (candidate.id == bid.jobId) {
        job = candidate;
        break;
      }
    }
    return ProviderBid(bid: bid, job: job);
  }

  void _replaceJob(Job updated) {
    final index = _jobs.indexWhere((job) => job.id == updated.id);
    if (index >= 0) _jobs[index] = updated;
  }
}

class SupabaseProviderJobRepository implements ProviderJobRepository {
  SupabaseProviderJobRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<Job>> loadFeed({required ProviderJobFilters filters}) async {
    final rows = await client
        .from('public_job_feed')
        .select()
        .order('created_at', ascending: false);
    final jobs = await Future.wait(
      (rows as List).whereType<Map<String, dynamic>>().map(_mapFeedJob),
    );
    return List<Job>.unmodifiable(filters.apply(jobs));
  }

  @override
  Future<Job?> loadJob(String jobId) async {
    final row = await client
        .from('public_job_feed')
        .select()
        .eq('id', jobId)
        .maybeSingle();
    return row == null ? null : _mapFeedJob(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<ProviderBid>> loadMyBids() async {
    final rows = await _bidsQuery()
        .eq('provider_id', userId)
        .order('created_at', ascending: false);
    return List<ProviderBid>.unmodifiable(
        (rows as List).whereType<Map<String, dynamic>>().map(_mapProviderBid));
  }

  @override
  Future<ProviderBid?> loadMyBidForJob(String jobId) async {
    final row = await _bidsQuery()
        .eq('provider_id', userId)
        .eq('job_id', jobId)
        .inFilter('status', ['pending', 'accepted']).maybeSingle();
    return row == null ? null : _mapProviderBid(Map<String, dynamic>.from(row));
  }

  @override
  Future<ProviderBid> saveBid(BidDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) throw StateError(validationError);
    final payload = <String, dynamic>{
      'job_id': draft.jobId,
      'provider_id': userId,
      'amount': draft.amountValue,
      'available_at': draft.availableAt.toUtc().toIso8601String(),
      'inclusions': draft.inclusions.trim(),
      'exclusions':
          draft.exclusions.trim().isEmpty ? null : draft.exclusions.trim(),
      'materials_note': draft.materialsNote.trim().isEmpty
          ? null
          : draft.materialsNote.trim(),
      'message': draft.message.trim().isEmpty ? null : draft.message.trim(),
      'status': 'pending',
    };
    Map<String, dynamic> row;
    if (draft.bidId == null) {
      final inserted =
          await client.from('bids').insert(payload).select().single();
      row = Map<String, dynamic>.from(inserted);
    } else {
      final updated = await client
          .from('bids')
          .update(payload)
          .eq('id', draft.bidId!)
          .eq('provider_id', userId)
          .eq('status', 'pending')
          .select()
          .single();
      row = Map<String, dynamic>.from(updated);
    }
    final job = await loadJob(draft.jobId);
    return ProviderBid(bid: _mapBid(row), job: job);
  }

  @override
  Future<void> withdrawBid(String bidId) async {
    await client
        .from('bids')
        .update({'status': 'withdrawn'})
        .eq('id', bidId)
        .eq('provider_id', userId)
        .eq('status', 'pending');
  }

  @override
  Future<List<Job>> loadAssignedJobs() async {
    final acceptedRows = await client
        .from('bids')
        .select('id')
        .eq('provider_id', userId)
        .eq('status', 'accepted');
    final acceptedIds = (acceptedRows as List)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    if (acceptedIds.isEmpty) return const [];
    final rows = await client
        .from('jobs')
        .select('*, service_categories(name_en), areas(area_name)')
        .inFilter('accepted_bid_id', acceptedIds)
        .inFilter('status', ['assigned', 'in_progress', 'completed']).order(
            'scheduled_at');
    final jobs = <Job>[];
    for (final row in (rows as List).whereType<Map<String, dynamic>>()) {
      jobs.add(await _mapAssignedJob(row));
    }
    return List<Job>.unmodifiable(jobs);
  }

  @override
  Future<Job?> loadAssignedJob(String jobId) async {
    final acceptedRows = await client
        .from('bids')
        .select('id')
        .eq('provider_id', userId)
        .eq('status', 'accepted');
    final acceptedIds = (acceptedRows as List)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    if (acceptedIds.isEmpty) return null;
    final row = await client
        .from('jobs')
        .select('*, service_categories(name_en), areas(area_name)')
        .eq('id', jobId)
        .inFilter('accepted_bid_id', acceptedIds)
        .maybeSingle();
    return row == null ? null : _mapAssignedJob(Map<String, dynamic>.from(row));
  }

  dynamic _bidsQuery() => client.from('bids').select(
      '*, jobs!bids_job_id_fkey!inner(id, category_id, area_id, title, description, public_location_text, budget_amount, time_window, scheduled_at, scheduled_end_at, urgency, status, created_at, service_categories(name_en), areas(area_name))');

  Future<Job> _mapFeedJob(Map<String, dynamic> row) async {
    final rawPhotoPaths = row['photo_paths'];
    final paths = rawPhotoPaths is List
        ? rawPhotoPaths
            .whereType<dynamic>()
            .map((item) => item is Map ? item['path'] : item)
            .whereType<String>()
            .toList()
        : <String>[];
    final signedPaths = await Future.wait(paths.map(_signPhoto));
    final scheduledAt = _parseDate(row['scheduled_at']);
    final scheduledEndAt = _parseDate(row['scheduled_end_at']);
    return Job(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled job',
      category: row['category_name'] as String? ??
          _categoryLabel(row['category_id'] as String?),
      area:
          row['area_name'] as String? ?? _areaLabel(row['area_id'] as String?),
      budget: (row['budget_amount'] as num?)?.toDouble() ?? 0,
      time: formatJobTimeWindow(scheduledAt, scheduledEndAt,
          row['time_window'] as String? ?? 'Flexible'),
      status: JobStatus.open,
      bidCount: (row['bid_count'] as num?)?.toInt() ?? 0,
      description: row['description'] as String? ?? '',
      urgent: row['urgency'] == 'urgent',
      categoryId: row['category_id'] as String?,
      areaId: row['area_id'] as String?,
      photoPaths: signedPaths.where((path) => path.isNotEmpty).toList(),
      createdAt: _parseDate(row['created_at']),
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
      expiresAt: _parseDate(row['expires_at']),
    );
  }

  Future<Job> _mapAssignedJob(Map<String, dynamic> row) async {
    final category = _asMap(row['service_categories']);
    final area = _asMap(row['areas']);
    final statusValue = row['status'] as String? ?? 'assigned';
    final status = JobStatus.values.firstWhere(
        (item) =>
            item.name == statusValue ||
            (item == JobStatus.inProgress && statusValue == 'in_progress'),
        orElse: () => JobStatus.assigned);
    final rawPhotoPaths = row['photo_paths'];
    final paths = rawPhotoPaths is List
        ? rawPhotoPaths
            .whereType<dynamic>()
            .map((item) => item is Map ? item['path'] : item)
            .whereType<String>()
            .toList()
        : <String>[];
    final signedPaths = await Future.wait(paths.map(_signPhoto));
    final scheduledAt = _parseDate(row['scheduled_at']);
    final scheduledEndAt = _parseDate(row['scheduled_end_at']);
    return Job(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled job',
      category: category?['name_en'] as String? ??
          _categoryLabel(row['category_id'] as String?),
      area: area?['area_name'] as String? ??
          row['public_location_text'] as String? ??
          _areaLabel(row['area_id'] as String?),
      budget: (row['budget_amount'] as num?)?.toDouble() ?? 0,
      time: formatJobTimeWindow(scheduledAt, scheduledEndAt,
          row['time_window'] as String? ?? 'Flexible'),
      status: status,
      bidCount: 0,
      description: row['description'] as String? ?? '',
      urgent: row['urgency'] == 'urgent',
      categoryId: row['category_id'] as String?,
      areaId: row['area_id'] as String?,
      fullAddress: row['full_address'] as String?,
      contactPhone: row['contact_phone'] as String?,
      contactWhatsapp: row['contact_whatsapp'] as String?,
      photoPaths: signedPaths.where((path) => path.isNotEmpty).toList(),
      createdAt: _parseDate(row['created_at']),
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
      expiresAt: _parseDate(row['expires_at']),
      acceptedBidId: row['accepted_bid_id'] as String?,
    );
  }

  ProviderBid _mapProviderBid(Map<String, dynamic> row) {
    final nested = _asMap(row['jobs']);
    final job = nested == null ? null : _mapNestedJob(nested);
    return ProviderBid(bid: _mapBid(row), job: job);
  }

  Job _mapNestedJob(Map<String, dynamic> row) {
    final category = _asMap(row['service_categories']);
    final area = _asMap(row['areas']);
    final statusValue = row['status'] as String? ?? 'open';
    final status = JobStatus.values.firstWhere(
      (item) =>
          item.name == statusValue ||
          (item == JobStatus.inProgress && statusValue == 'in_progress'),
      orElse: () => JobStatus.open,
    );
    final scheduledAt = _parseDate(row['scheduled_at']);
    final scheduledEndAt = _parseDate(row['scheduled_end_at']);
    return Job(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled job',
      category: category?['name_en'] as String? ??
          _categoryLabel(row['category_id'] as String?),
      area: area?['area_name'] as String? ??
          row['public_location_text'] as String? ??
          _areaLabel(row['area_id'] as String?),
      budget: (row['budget_amount'] as num?)?.toDouble() ?? 0,
      time: formatJobTimeWindow(scheduledAt, scheduledEndAt,
          row['time_window'] as String? ?? 'Flexible'),
      status: status,
      bidCount: 0,
      description: row['description'] as String? ?? '',
      urgent: row['urgency'] == 'urgent',
      categoryId: row['category_id'] as String?,
      areaId: row['area_id'] as String?,
      createdAt: _parseDate(row['created_at']),
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
    );
  }

  Bid _mapBid(Map<String, dynamic> row) {
    final statusValue = row['status'] as String? ?? 'pending';
    final status = BidStatus.values.firstWhere(
        (item) => item.name == statusValue,
        orElse: () => BidStatus.pending);
    final availableAt = _parseDate(row['available_at']);
    return Bid(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      providerName: 'Your provider profile',
      providerCategory: 'Provider offer',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      availableAt: availableAt == null ? 'Flexible' : _displayDate(availableAt),
      inclusions: row['inclusions'] as String? ?? '',
      exclusions: row['exclusions'] as String? ?? '',
      status: status,
      rating: 0,
      completedJobs: 0,
      providerId: row['provider_id'] as String?,
      materialsNote: row['materials_note'] as String?,
      message: row['message'] as String?,
      availableAtDate: availableAt,
      createdAt: _parseDate(row['created_at']),
    );
  }

  Future<String> _signPhoto(String path) async {
    try {
      return await client.storage
          .from('job-photos')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return '';
    }
  }
}

Map<String, dynamic>? _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

String _displayDate(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'pm' : 'am';
  return '${date.day}/${date.month}/${date.year}, $hour:$minute$suffix';
}

String _categoryLabel(String? id) {
  for (final option in serviceCategoryOptions) {
    if (option.id == id) return option.label;
  }
  return 'Service';
}

String _areaLabel(String? id) {
  for (final option in serviceAreaOptions) {
    if (option.id == id) return option.label;
  }
  return 'Johor Bahru';
}
