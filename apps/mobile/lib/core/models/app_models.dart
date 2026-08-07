enum AppMode { customer, provider }

enum JobStatus {
  draft,
  open,
  assigned,
  inProgress,
  completed,
  cancelled,
  expired
}

enum BidStatus { pending, accepted, rejected, withdrawn, expired }

enum VerificationStatus { notApplied, pending, approved, rejected, suspended }

enum NotificationType {
  newJob,
  newBid,
  bidAccepted,
  jobAssigned,
  jobExpiring,
  jobExpired,
  providerApproved,
  providerRejected,
  providerSuspended,
  providerCategoryApproved,
  providerCategoryRejected,
  jobStarted,
  jobCompleted,
  jobCancelled,
  noShow,
  generic
}

extension NotificationTypeLabel on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.newJob:
        return 'New matching job';
      case NotificationType.newBid:
        return 'New offer';
      case NotificationType.bidAccepted:
        return 'Offer accepted';
      case NotificationType.jobAssigned:
        return 'Job assigned';
      case NotificationType.jobExpiring:
        return 'Job expiring soon';
      case NotificationType.jobExpired:
        return 'Job expired';
      case NotificationType.providerApproved:
        return 'Provider approved';
      case NotificationType.providerRejected:
        return 'Provider verification update';
      case NotificationType.providerSuspended:
        return 'Provider account update';
      case NotificationType.providerCategoryApproved:
        return 'Service category approved';
      case NotificationType.providerCategoryRejected:
        return 'Service category needs changes';
      case NotificationType.jobStarted:
        return 'Job started';
      case NotificationType.jobCompleted:
        return 'Job completed';
      case NotificationType.jobCancelled:
        return 'Job cancelled';
      case NotificationType.noShow:
        return 'No-show reported';
      case NotificationType.generic:
        return 'Notification';
    }
  }
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.category,
    required this.area,
    required this.budget,
    required this.time,
    required this.status,
    required this.bidCount,
    required this.description,
    this.urgent = false,
    this.categoryId,
    this.areaId,
    this.fullAddress,
    this.contactPhone,
    this.contactWhatsapp,
    this.photoPaths = const [],
    this.createdAt,
    this.scheduledAt,
    this.scheduledEndAt,
    this.expiresAt,
    this.acceptedBidId,
  });

  final String id;
  final String title;
  final String category;
  final String area;
  final double budget;
  final String time;
  final JobStatus status;
  final int bidCount;
  final String description;
  final bool urgent;
  final String? categoryId;
  final String? areaId;
  final String? fullAddress;
  final String? contactPhone;
  final String? contactWhatsapp;
  final List<String> photoPaths;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? scheduledEndAt;
  final DateTime? expiresAt;
  final String? acceptedBidId;

  Job copyWith(
          {JobStatus? status,
          int? bidCount,
          DateTime? createdAt,
          DateTime? scheduledAt,
          DateTime? scheduledEndAt,
          DateTime? expiresAt,
          String? acceptedBidId}) =>
      Job(
        id: id,
        title: title,
        category: category,
        area: area,
        budget: budget,
        time: time,
        status: status ?? this.status,
        bidCount: bidCount ?? this.bidCount,
        description: description,
        urgent: urgent,
        categoryId: categoryId,
        areaId: areaId,
        fullAddress: fullAddress,
        contactPhone: contactPhone,
        contactWhatsapp: contactWhatsapp,
        photoPaths: photoPaths,
        createdAt: createdAt ?? this.createdAt,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        scheduledEndAt: scheduledEndAt ?? this.scheduledEndAt,
        expiresAt: expiresAt ?? this.expiresAt,
        acceptedBidId: acceptedBidId ?? this.acceptedBidId,
      );
}

class Bid {
  const Bid({
    required this.id,
    required this.jobId,
    required this.providerName,
    required this.providerCategory,
    required this.amount,
    required this.availableAt,
    required this.inclusions,
    required this.exclusions,
    required this.status,
    required this.rating,
    required this.completedJobs,
    this.verified = true,
    this.providerId,
    this.materialsNote,
    this.message,
    this.availableAtDate,
    this.createdAt,
  });

  final String id;
  final String jobId;
  final String providerName;
  final String providerCategory;
  final double amount;
  final String availableAt;
  final String inclusions;
  final String exclusions;
  final BidStatus status;
  final double rating;
  final int completedJobs;
  final bool verified;
  final String? providerId;
  final String? materialsNote;
  final String? message;
  final DateTime? availableAtDate;
  final DateTime? createdAt;

  Bid copyWith({
    String? id,
    String? jobId,
    String? providerName,
    String? providerCategory,
    double? amount,
    String? availableAt,
    String? inclusions,
    String? exclusions,
    BidStatus? status,
    double? rating,
    int? completedJobs,
    bool? verified,
    String? providerId,
    String? materialsNote,
    String? message,
    DateTime? availableAtDate,
    DateTime? createdAt,
  }) =>
      Bid(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        providerName: providerName ?? this.providerName,
        providerCategory: providerCategory ?? this.providerCategory,
        amount: amount ?? this.amount,
        availableAt: availableAt ?? this.availableAt,
        inclusions: inclusions ?? this.inclusions,
        exclusions: exclusions ?? this.exclusions,
        status: status ?? this.status,
        rating: rating ?? this.rating,
        completedJobs: completedJobs ?? this.completedJobs,
        verified: verified ?? this.verified,
        providerId: providerId ?? this.providerId,
        materialsNote: materialsNote ?? this.materialsNote,
        message: message ?? this.message,
        availableAtDate: availableAtDate ?? this.availableAtDate,
        createdAt: createdAt ?? this.createdAt,
      );
}

class ProviderProfile {
  const ProviderProfile({
    required this.name,
    required this.category,
    required this.area,
    required this.rating,
    required this.completedJobs,
    required this.bio,
    required this.verification,
    this.id,
    this.avatarPath,
    this.portfolioUrls = const [],
    this.isAvailable = true,
  });

  final String? id;
  final String name;
  final String category;
  final String area;
  final double rating;
  final int completedJobs;
  final String bio;
  final VerificationStatus verification;
  final String? avatarPath;
  final List<String> portfolioUrls;
  final bool isAvailable;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
    this.recipientId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId;
  final String? recipientId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        referenceType: referenceType,
        referenceId: referenceId,
        recipientId: recipientId,
      );
}
