import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/fake_data.dart';
import '../../core/models/app_models.dart';
import '../job_lifecycle/job_lifecycle_models.dart';
import 'customer_job_models.dart';

abstract interface class CustomerJobRepository {
  Future<List<Job>> loadMyJobs();
  Future<Job> saveDraft(JobDraft draft, {required bool publish});
  Future<void> cancelJob(String jobId, {String? reason});
}

class FakeCustomerJobRepository implements CustomerJobRepository {
  FakeCustomerJobRepository(List<Job> initialJobs)
      : _jobs = List<Job>.from(initialJobs);

  final List<Job> _jobs;
  var _sequence = 900;

  @override
  Future<List<Job>> loadMyJobs() async => List<Job>.unmodifiable(_jobs);

  @override
  Future<Job> saveDraft(JobDraft draft, {required bool publish}) async {
    final job = draft
        .toPreviewJob()
        .copyWith(status: publish ? JobStatus.open : JobStatus.draft);
    final saved = Job(
      id: 'local-job-${_sequence++}',
      title: job.title,
      category: job.category,
      area: job.area,
      budget: job.budget,
      time: job.time,
      status: job.status,
      bidCount: 0,
      description: job.description,
      urgent: job.urgent,
      categoryId: job.categoryId,
      areaId: job.areaId,
      fullAddress: job.fullAddress,
      contactPhone: job.contactPhone,
      contactWhatsapp: job.contactWhatsapp,
      photoPaths: job.photoPaths,
      createdAt: DateTime.now(),
      expiresAt: publish ? DateTime.now().add(const Duration(days: 7)) : null,
    );
    _jobs.insert(0, saved);
    return saved;
  }

  @override
  Future<void> cancelJob(String jobId, {String? reason}) async {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index < 0) throw StateError('Job not found');
    final current = _jobs[index];
    if (current.status != JobStatus.open &&
        current.status != JobStatus.assigned &&
        current.status != JobStatus.inProgress) {
      throw StateError('This job cannot be cancelled in its current state.');
    }
    _jobs[index] = current.copyWith(status: JobStatus.cancelled);
  }

  Future<int> expireOpenJobs({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    var expiredCount = 0;
    for (var index = 0; index < _jobs.length; index++) {
      final job = _jobs[index];
      if (job.status != JobStatus.open ||
          job.expiresAt == null ||
          job.expiresAt!.isAfter(currentTime)) {
        continue;
      }
      _jobs[index] = job.copyWith(status: JobStatus.expired);
      fakeJobEvents.insert(
        0,
        JobEventRecord(
          id: 'local-event-${_sequence++}',
          jobId: job.id,
          eventType: 'job_expired',
          createdAt: currentTime,
          actorId: null,
        ),
      );
      fakeNotifications.insert(
        0,
        AppNotification(
          id: 'local-notification-${_sequence++}',
          type: NotificationType.jobExpired,
          title: 'Job expired',
          body: 'The job stopped accepting offers after its expiry time.',
          isRead: false,
          createdAt: currentTime,
          referenceType: 'job',
          referenceId: job.id,
        ),
      );
      expiredCount++;
    }
    return expiredCount;
  }
}

class SupabaseCustomerJobRepository implements CustomerJobRepository {
  SupabaseCustomerJobRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<Job>> loadMyJobs() async {
    final rows = await client
        .from('jobs')
        .select('*, service_categories(name_en), areas(area_name)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(_mapJob)
        .toList();
  }

  @override
  Future<Job> saveDraft(JobDraft draft, {required bool publish}) async {
    final validationError = draft.validate();
    if (validationError != null) throw StateError(validationError);
    final row = await client
        .from('jobs')
        .insert({
          'customer_id': userId,
          'category_id': draft.category.id,
          'area_id': draft.area.id,
          'title': draft.title.trim(),
          'description': draft.description.trim(),
          'public_location_text': draft.area.label,
          'full_address': draft.fullAddress.trim(),
          'budget_amount': draft.budgetAmount,
          'time_window': draft.timeWindow,
          'urgency': draft.urgent ? 'urgent' : 'normal',
          'status': 'draft',
          'expires_at': publish
              ? DateTime.now()
                  .add(const Duration(days: 7))
                  .toUtc()
                  .toIso8601String()
              : null,
          'contact_phone': draft.contactPhone.trim(),
          'contact_whatsapp': draft.contactWhatsapp.trim().isEmpty
              ? null
              : draft.contactWhatsapp.trim(),
        })
        .select('*, service_categories(name_en), areas(area_name)')
        .single();
    final job = _mapJob(row);
    await _uploadPhotos(job.id, draft.photoPaths);
    if (publish) {
      final publishedRow = await client
          .from('jobs')
          .update({'status': 'open'})
          .eq('id', job.id)
          .eq('customer_id', userId)
          .eq('status', 'draft')
          .select('*, service_categories(name_en), areas(area_name)')
          .single();
      return _mapJob(publishedRow);
    }
    return job;
  }

  Future<void> _uploadPhotos(String jobId, List<String> paths) async {
    if (paths.isEmpty) return;
    for (var index = 0; index < paths.length; index++) {
      final file = File(paths[index]);
      if (!file.existsSync()) {
        throw StateError('A selected photo is no longer available.');
      }
      final storagePath =
          '$jobId/${DateTime.now().microsecondsSinceEpoch}_$index.jpg';
      await client.storage.from('job-photos').upload(storagePath, file,
          fileOptions: const FileOptions(upsert: false));
      await client.from('job_photos').insert(
          {'job_id': jobId, 'storage_path': storagePath, 'sort_order': index});
    }
  }

  @override
  Future<void> cancelJob(String jobId, {String? reason}) async {
    await client
        .rpc('cancel_job', params: {'p_job_id': jobId, 'p_reason': reason});
  }

  Job _mapJob(Map<String, dynamic> row) {
    final category = row['service_categories'];
    final area = row['areas'];
    final categoryMap =
        category is Map<String, dynamic> ? category : const <String, dynamic>{};
    final areaMap =
        area is Map<String, dynamic> ? area : const <String, dynamic>{};
    final statusValue = row['status'] as String? ?? 'draft';
    final status = JobStatus.values.firstWhere(
        (item) =>
            item.name == statusValue ||
            (item == JobStatus.inProgress && statusValue == 'in_progress'),
        orElse: () => JobStatus.draft);
    return Job(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled job',
      category: categoryMap['name_en'] as String? ?? 'Service',
      area: areaMap['area_name'] as String? ??
          row['public_location_text'] as String? ??
          'Johor Bahru',
      budget: (row['budget_amount'] as num?)?.toDouble() ?? 0,
      time: row['time_window'] as String? ?? 'Flexible',
      status: status,
      bidCount: 0,
      description: row['description'] as String? ?? '',
      urgent: row['urgency'] == 'urgent',
      categoryId: row['category_id'] as String?,
      areaId: row['area_id'] as String?,
      fullAddress: row['full_address'] as String?,
      contactPhone: row['contact_phone'] as String?,
      contactWhatsapp: row['contact_whatsapp'] as String?,
      photoPaths: _photoPaths(row),
      createdAt: _parseDate(row['created_at']),
      scheduledAt: _parseDate(row['scheduled_at']),
      expiresAt: _parseDate(row['expires_at']),
      acceptedBidId: row['accepted_bid_id'] as String?,
    );
  }

  List<String> _photoPaths(Map<String, dynamic> row) {
    final raw = row['photo_paths'];
    if (raw is! List) return const [];
    return raw
        .whereType<dynamic>()
        .map((value) => value is Map ? value['path'] : value)
        .whereType<String>()
        .toList();
  }

  DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

class CustomerJobsState {
  const CustomerJobsState(
      {this.initialized = false,
      this.isLoading = false,
      this.jobs = const [],
      this.error});

  final bool initialized;
  final bool isLoading;
  final List<Job> jobs;
  final String? error;

  CustomerJobsState copyWith(
          {bool? initialized,
          bool? isLoading,
          List<Job>? jobs,
          String? error,
          bool clearError = false}) =>
      CustomerJobsState(
          initialized: initialized ?? this.initialized,
          isLoading: isLoading ?? this.isLoading,
          jobs: jobs ?? this.jobs,
          error: clearError ? null : error ?? this.error);
}
