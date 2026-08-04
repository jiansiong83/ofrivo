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

  Job copyWith({JobStatus? status, int? bidCount}) => Job(
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
