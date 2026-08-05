import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/fake_data.dart';
import '../../core/models/app_models.dart';
import 'job_lifecycle_models.dart';

abstract interface class JobLifecycleRepository {
  Future<JobTransition> startJob(String jobId);

  Future<JobTransition> completeJob(String jobId);

  Future<JobTransition> cancelJob(String jobId, {String? reason});

  Future<JobEventRecord> markNoShow(String jobId, {String? reason});

  Future<List<JobEventRecord>> loadEvents(String jobId);

  Future<List<ReviewRecord>> loadReviews(String jobId);

  Future<ReviewRecord> submitReview(
      {required String jobId, required ReviewDraft draft});

  Future<ReportRecord> submitReport(
      {required String jobId, required ReportDraft draft});
}

class FakeJobLifecycleRepository implements JobLifecycleRepository {
  FakeJobLifecycleRepository(
      {required List<Job> initialJobs,
      required List<Bid> initialBids,
      required this.role,
      this.providerId = 'demo-user'})
      : _jobs = initialJobs,
        _bids = initialBids;

  final List<Job> _jobs;
  final List<Bid> _bids;
  final AppMode role;
  final String providerId;
  final String customerId = 'customer-demo';
  var _sequence = 1000;

  @override
  Future<JobTransition> startJob(String jobId) async {
    final job = _findJob(jobId);
    if (role != AppMode.provider) {
      throw StateError('Only the accepted provider can start this job.');
    }
    if (job.status != JobStatus.assigned) {
      throw StateError('Only an assigned job can be started.');
    }
    if (_acceptedProvider(jobId) != providerId) {
      throw StateError('Only the accepted provider can start this job.');
    }
    return _transition(job, JobStatus.inProgress, 'job_started',
        'Your provider marked the job as started.');
  }

  @override
  Future<JobTransition> completeJob(String jobId) async {
    final job = _findJob(jobId);
    if (job.status != JobStatus.inProgress) {
      throw StateError('Only an in-progress job can be completed.');
    }
    if (role == AppMode.provider && _acceptedProvider(jobId) != providerId) {
      throw StateError('Only the accepted provider can complete this job.');
    }
    return _transition(job, JobStatus.completed, 'job_completed',
        'The job is ready for review.');
  }

  @override
  Future<JobTransition> cancelJob(String jobId, {String? reason}) async {
    final job = _findJob(jobId);
    if (job.status != JobStatus.open &&
        job.status != JobStatus.assigned &&
        job.status != JobStatus.inProgress) {
      throw StateError('This job cannot be cancelled in its current state.');
    }
    if (role == AppMode.provider && _acceptedProvider(jobId) != providerId) {
      throw StateError('Only the accepted provider can cancel this job.');
    }
    return _transition(
        job,
        JobStatus.cancelled,
        'job_cancelled',
        reason?.trim().isNotEmpty == true
            ? reason!.trim()
            : 'A participant cancelled the job.');
  }

  @override
  Future<JobEventRecord> markNoShow(String jobId, {String? reason}) async {
    final job = _findJob(jobId);
    if (job.status != JobStatus.assigned &&
        job.status != JobStatus.inProgress) {
      throw StateError(
          'A no-show can only be marked on an assigned or in-progress job.');
    }
    final acceptedProvider = _acceptedProvider(jobId);
    if (acceptedProvider == null) {
      throw StateError('This job has no accepted provider.');
    }
    final reportedUserId =
        role == AppMode.customer ? acceptedProvider : customerId;
    final reporterId = role == AppMode.customer ? customerId : providerId;
    if (reporterId == reportedUserId) {
      throw StateError('You cannot mark yourself as a no-show.');
    }
    if (fakeJobEvents.any((event) =>
        event.jobId == jobId &&
        event.eventType == 'no_show_marked' &&
        event.metadata['reported_user_id'] == reportedUserId)) {
      throw StateError(
          'A no-show has already been marked for this participant.');
    }
    final event = JobEventRecord(
      id: 'local-event-${_sequence++}',
      jobId: jobId,
      eventType: 'no_show_marked',
      createdAt: DateTime.now(),
      actorId: reporterId,
      metadata: {
        'reported_user_id': reportedUserId,
        'reason': reason?.trim().isNotEmpty == true
            ? reason!.trim()
            : 'No-show reported by a job participant.',
      },
    );
    fakeJobEvents.insert(0, event);
    fakeNotifications.insert(
      0,
      AppNotification(
        id: 'local-notification-${_sequence++}',
        type: NotificationType.noShow,
        title: 'No-show reported',
        body: 'A job participant reported a no-show event.',
        isRead: false,
        createdAt: DateTime.now(),
        referenceType: 'job',
        referenceId: jobId,
      ),
    );
    return event;
  }

  @override
  Future<List<JobEventRecord>> loadEvents(String jobId) async =>
      List<JobEventRecord>.unmodifiable(
          fakeJobEvents.where((event) => event.jobId == jobId).toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt)));

  @override
  Future<List<ReviewRecord>> loadReviews(String jobId) async =>
      List<ReviewRecord>.unmodifiable(
          fakeReviews.where((review) => review.jobId == jobId).toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt)));

  @override
  Future<ReviewRecord> submitReview(
      {required String jobId, required ReviewDraft draft}) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
    final job = _findJob(jobId);
    if (job.status != JobStatus.completed) {
      throw StateError('Reviews are available after the job is completed.');
    }
    final reviewerId = role == AppMode.customer ? customerId : providerId;
    if (fakeReviews.any(
        (review) => review.jobId == jobId && review.reviewerId == reviewerId)) {
      throw StateError('You have already reviewed this job.');
    }
    final review = ReviewRecord(
        id: 'local-review-${_sequence++}',
        jobId: jobId,
        reviewerId: reviewerId,
        revieweeId: role == AppMode.customer
            ? (_acceptedProvider(jobId) ?? providerId)
            : customerId,
        rating: draft.rating,
        comment: draft.comment.trim(),
        createdAt: DateTime.now());
    fakeReviews.insert(0, review);
    return review;
  }

  @override
  Future<ReportRecord> submitReport(
      {required String jobId, required ReportDraft draft}) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
    final job = _findJob(jobId);
    if (job.status != JobStatus.completed &&
        job.status != JobStatus.cancelled &&
        job.status != JobStatus.inProgress) {
      throw StateError(
          'Reports are available after work has started or finished.');
    }
    final reporterId = role == AppMode.customer ? customerId : providerId;
    final report = ReportRecord(
        id: 'local-report-${_sequence++}',
        jobId: jobId,
        reporterId: reporterId,
        reportedUserId: role == AppMode.customer
            ? (_acceptedProvider(jobId) ?? providerId)
            : customerId,
        reasonCode: draft.reasonCode,
        description: draft.description.trim(),
        status: 'open',
        createdAt: DateTime.now());
    fakeReports.insert(0, report);
    return report;
  }

  Job _findJob(String jobId) {
    for (final job in _jobs) {
      if (job.id == jobId) return job;
    }
    throw StateError('Job not found.');
  }

  String? _acceptedProvider(String jobId) {
    final job = _findJob(jobId);
    for (final bid in _bids) {
      if (bid.id == job.acceptedBidId && bid.status == BidStatus.accepted) {
        return bid.providerId;
      }
    }
    return null;
  }

  JobTransition _transition(
      Job job, JobStatus status, String eventType, String message) {
    final index = _jobs.indexWhere((candidate) => candidate.id == job.id);
    if (index < 0) throw StateError('Job not found.');
    _jobs[index] = job.copyWith(status: status);
    final event = JobEventRecord(
        id: 'local-event-${_sequence++}',
        jobId: job.id,
        eventType: eventType,
        createdAt: DateTime.now(),
        actorId: role == AppMode.customer ? customerId : providerId);
    fakeJobEvents.insert(0, event);
    fakeNotifications.insert(
        0,
        AppNotification(
            id: 'local-notification-${_sequence++}',
            type: eventType == 'job_started'
                ? NotificationType.jobStarted
                : eventType == 'job_completed'
                    ? NotificationType.jobCompleted
                    : NotificationType.jobCancelled,
            title: eventType == 'job_started'
                ? 'Job started'
                : eventType == 'job_completed'
                    ? 'Job completed'
                    : 'Job cancelled',
            body: message,
            isRead: false,
            createdAt: DateTime.now(),
            referenceType: 'job',
            referenceId: job.id));
    return JobTransition(
        jobId: job.id, status: status, providerId: _acceptedProvider(job.id));
  }
}

class SupabaseJobLifecycleRepository implements JobLifecycleRepository {
  SupabaseJobLifecycleRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<JobTransition> startJob(String jobId) =>
      _rpcTransition('start_job', {'p_job_id': jobId}, jobId);

  @override
  Future<JobTransition> completeJob(String jobId) =>
      _rpcTransition('complete_job', {'p_job_id': jobId}, jobId);

  @override
  Future<JobTransition> cancelJob(String jobId, {String? reason}) =>
      _rpcTransition(
          'cancel_job', {'p_job_id': jobId, 'p_reason': reason}, jobId);

  @override
  Future<JobEventRecord> markNoShow(String jobId, {String? reason}) async {
    final raw = await client.rpc('mark_no_show', params: {
      'p_job_id': jobId,
      'p_reason': reason,
    });
    final value =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    return JobEventRecord(
      id: value['event_id'] as String? ?? 'no-show-$jobId',
      jobId: value['job_id'] as String? ?? jobId,
      eventType: value['event_type'] as String? ?? 'no_show_marked',
      createdAt: _date(value['created_at']),
      actorId: value['actor_id'] as String?,
      metadata: value['metadata'] is Map
          ? Map<String, dynamic>.from(value['metadata'] as Map)
          : const <String, dynamic>{},
    );
  }

  @override
  Future<List<JobEventRecord>> loadEvents(String jobId) async {
    final rows = await client
        .from('job_events')
        .select()
        .eq('job_id', jobId)
        .order('created_at', ascending: false);
    return List<JobEventRecord>.unmodifiable(
        (rows as List).whereType<Map<String, dynamic>>().map(_mapEvent));
  }

  @override
  Future<List<ReviewRecord>> loadReviews(String jobId) async {
    final rows = await client
        .from('reviews')
        .select()
        .eq('job_id', jobId)
        .order('created_at', ascending: false);
    return List<ReviewRecord>.unmodifiable(
        (rows as List).whereType<Map<String, dynamic>>().map(_mapReview));
  }

  @override
  Future<ReviewRecord> submitReview(
      {required String jobId, required ReviewDraft draft}) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
    final participants = await _participants(jobId);
    final revieweeId = participants.customerId == userId
        ? participants.providerId
        : participants.customerId;
    final row = await client
        .from('reviews')
        .insert({
          'job_id': jobId,
          'reviewer_id': userId,
          'reviewee_id': revieweeId,
          'rating': draft.rating,
          'comment': draft.comment.trim().isEmpty ? null : draft.comment.trim()
        })
        .select()
        .single();
    return _mapReview(Map<String, dynamic>.from(row));
  }

  @override
  Future<ReportRecord> submitReport(
      {required String jobId, required ReportDraft draft}) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
    final participants = await _participants(jobId);
    final reportedUserId = participants.customerId == userId
        ? participants.providerId
        : participants.customerId;
    final row = await client
        .from('reports')
        .insert({
          'job_id': jobId,
          'reporter_id': userId,
          'reported_user_id': reportedUserId,
          'reason_code': draft.reasonCode.trim(),
          'description': draft.description.trim()
        })
        .select()
        .single();
    return _mapReport(Map<String, dynamic>.from(row));
  }

  Future<JobTransition> _rpcTransition(
      String function, Map<String, dynamic> params, String jobId) async {
    final raw = await client.rpc(function, params: params);
    final value =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    return JobTransition(
        jobId: value['job_id'] as String? ?? jobId,
        status: _status(value['job_status'] as String?),
        providerId: value['provider_id'] as String?);
  }

  Future<JobParticipants> _participants(String jobId) async {
    final job = await client
        .from('jobs')
        .select('customer_id, accepted_bid_id')
        .eq('id', jobId)
        .single();
    final acceptedBidId = job['accepted_bid_id'] as String?;
    if (acceptedBidId == null) {
      throw StateError('This job has no accepted provider.');
    }
    final bid = await client
        .from('bids')
        .select('provider_id')
        .eq('id', acceptedBidId)
        .single();
    return JobParticipants(
        customerId: job['customer_id'] as String,
        providerId: bid['provider_id'] as String);
  }

  JobEventRecord _mapEvent(Map<String, dynamic> row) => JobEventRecord(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      eventType: row['event_type'] as String? ?? 'job_update',
      actorId: row['actor_id'] as String?,
      metadata: row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'])
          : const {},
      createdAt: _date(row['created_at']));

  ReviewRecord _mapReview(Map<String, dynamic> row) => ReviewRecord(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      reviewerId: row['reviewer_id'] as String,
      revieweeId: row['reviewee_id'] as String,
      rating: (row['rating'] as num?)?.toInt() ?? 0,
      comment: row['comment'] as String? ?? '',
      createdAt: _date(row['created_at']));

  ReportRecord _mapReport(Map<String, dynamic> row) => ReportRecord(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      reporterId: row['reporter_id'] as String,
      reportedUserId: row['reported_user_id'] as String,
      reasonCode: row['reason_code'] as String? ?? 'Other',
      description: row['description'] as String? ?? '',
      status: row['status'] as String? ?? 'open',
      createdAt: _date(row['created_at']));

  static DateTime _date(dynamic value) => value is String
      ? DateTime.tryParse(value)?.toLocal() ?? DateTime.now()
      : DateTime.now();

  static JobStatus _status(String? value) => JobStatus.values.firstWhere(
      (item) =>
          item.name == value ||
          (item == JobStatus.inProgress && value == 'in_progress'),
      orElse: () => JobStatus.assigned);
}
