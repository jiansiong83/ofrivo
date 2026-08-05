import '../../core/models/app_models.dart';

class JobTransition {
  const JobTransition(
      {required this.jobId, required this.status, this.providerId});

  final String jobId;
  final JobStatus status;
  final String? providerId;
}

class JobParticipants {
  const JobParticipants({required this.customerId, required this.providerId});

  final String customerId;
  final String providerId;
}

class JobEventRecord {
  const JobEventRecord(
      {required this.id,
      required this.jobId,
      required this.eventType,
      required this.createdAt,
      this.actorId,
      this.metadata = const {}});

  final String id;
  final String jobId;
  final String eventType;
  final DateTime createdAt;
  final String? actorId;
  final Map<String, dynamic> metadata;
}

class ReviewRecord {
  const ReviewRecord(
      {required this.id,
      required this.jobId,
      required this.reviewerId,
      required this.revieweeId,
      required this.rating,
      required this.comment,
      required this.createdAt,
      this.punctualityRating = 5,
      this.qualityRating = 5,
      this.communicationRating = 5});

  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int punctualityRating;
  final int qualityRating;
  final int communicationRating;
}

class ReportRecord {
  const ReportRecord(
      {required this.id,
      required this.jobId,
      required this.reporterId,
      required this.reportedUserId,
      required this.reasonCode,
      required this.description,
      required this.status,
      required this.createdAt});

  final String id;
  final String jobId;
  final String reporterId;
  final String reportedUserId;
  final String reasonCode;
  final String description;
  final String status;
  final DateTime createdAt;
}

class JobLifecycleState {
  const JobLifecycleState(
      {this.initialized = false,
      this.isLoading = false,
      this.isSubmitting = false,
      this.status,
      this.events = const [],
      this.reviews = const [],
      this.error,
      this.info});

  final bool initialized;
  final bool isLoading;
  final bool isSubmitting;
  final JobStatus? status;
  final List<JobEventRecord> events;
  final List<ReviewRecord> reviews;
  final String? error;
  final String? info;

  JobLifecycleState copyWith(
          {bool? initialized,
          bool? isLoading,
          bool? isSubmitting,
          JobStatus? status,
          List<JobEventRecord>? events,
          List<ReviewRecord>? reviews,
          String? error,
          String? info,
          bool clearError = false,
          bool clearInfo = false}) =>
      JobLifecycleState(
        initialized: initialized ?? this.initialized,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        status: status ?? this.status,
        events: events ?? this.events,
        reviews: reviews ?? this.reviews,
        error: clearError ? null : error ?? this.error,
        info: clearInfo ? null : info ?? this.info,
      );
}

class ReviewDraft {
  const ReviewDraft(
      {required this.rating,
      required this.comment,
      this.punctualityRating = 5,
      this.qualityRating = 5,
      this.communicationRating = 5});

  final int rating;
  final String comment;
  final int punctualityRating;
  final int qualityRating;
  final int communicationRating;

  String? validate() {
    if (rating < 1 || rating > 5) return 'Choose a rating from 1 to 5 stars.';
    if (punctualityRating < 1 || punctualityRating > 5) {
      return 'Choose a punctuality rating from 1 to 5 stars.';
    }
    if (qualityRating < 1 || qualityRating > 5) {
      return 'Choose a quality rating from 1 to 5 stars.';
    }
    if (communicationRating < 1 || communicationRating > 5) {
      return 'Choose a communication rating from 1 to 5 stars.';
    }
    if (comment.trim().length > 1000) {
      return 'Keep your review under 1,000 characters.';
    }
    return null;
  }
}

class ReportDraft {
  const ReportDraft({required this.reasonCode, required this.description});

  final String reasonCode;
  final String description;

  String? validate() {
    if (reasonCode.trim().isEmpty) return 'Choose a report reason.';
    if (description.trim().length < 10) {
      return 'Add at least 10 characters so the report can be reviewed.';
    }
    if (description.trim().length > 2000) {
      return 'Keep the report under 2,000 characters.';
    }
    return null;
  }
}

const reportReasonOptions = <String>[
  'No-show or late arrival',
  'Unsafe or abusive behaviour',
  'Payment or price dispute',
  'Work quality concern',
  'Other',
];
