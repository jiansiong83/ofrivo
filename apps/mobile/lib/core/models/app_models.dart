enum AppMode { customer, provider }

enum JobStatus { draft, open, assigned, inProgress, completed, cancelled, expired }

enum BidStatus { pending, accepted, rejected, withdrawn, expired }

enum VerificationStatus { notApplied, pending, approved, rejected, suspended }

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
    this.expiresAt,
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
  final DateTime? expiresAt;

  Job copyWith({JobStatus? status, int? bidCount, DateTime? createdAt, DateTime? scheduledAt, DateTime? expiresAt}) => Job(
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
        expiresAt: expiresAt ?? this.expiresAt,
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
  }) => Bid(
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
  });

  final String name;
  final String category;
  final String area;
  final double rating;
  final int completedJobs;
  final String bio;
  final VerificationStatus verification;
}
