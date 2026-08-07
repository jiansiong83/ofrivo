import '../../core/models/service_options.dart';

enum ProviderApplicationStatus {
  notApplied,
  pending,
  approved,
  rejected,
  suspended
}

enum ProviderCategoryStatus { pending, approved, rejected }

ProviderCategoryStatus providerCategoryStatusFromValue(String? value) {
  switch (value) {
    case 'approved':
      return ProviderCategoryStatus.approved;
    case 'rejected':
      return ProviderCategoryStatus.rejected;
    default:
      return ProviderCategoryStatus.pending;
  }
}

class ProviderCategorySelection {
  const ProviderCategorySelection({
    required this.category,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.adminNote,
  });

  final ServiceCategoryOption category;
  final ProviderCategoryStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? adminNote;
}

ProviderApplicationStatus providerApplicationStatusFromValue(String? value) {
  switch (value) {
    case 'pending':
      return ProviderApplicationStatus.pending;
    case 'approved':
      return ProviderApplicationStatus.approved;
    case 'rejected':
      return ProviderApplicationStatus.rejected;
    case 'suspended':
      return ProviderApplicationStatus.suspended;
    default:
      return ProviderApplicationStatus.notApplied;
  }
}

class ProviderApplicationDraft {
  const ProviderApplicationDraft({
    required this.displayName,
    required this.bio,
    required this.categories,
    required this.areas,
    required this.icFrontPath,
    required this.icBackPath,
    required this.selfiePath,
    this.ssmPath,
    this.certificatePaths = const [],
    this.workPhotoPaths = const [],
  });

  final String displayName;
  final String bio;
  final List<ServiceCategoryOption> categories;
  final List<ServiceAreaOption> areas;
  final String? icFrontPath;
  final String? icBackPath;
  final String? selfiePath;
  final String? ssmPath;
  final List<String> certificatePaths;
  final List<String> workPhotoPaths;

  List<String> get categoryIds => [for (final item in categories) item.id];
  List<String> get areaIds => [for (final item in areas) item.id];

  String? validate() {
    if (displayName.trim().length < 2) {
      return 'Add a business or display name.';
    }
    if (bio.trim().length < 10) {
      return 'Tell customers a little more about your work.';
    }
    if (categories.isEmpty) return 'Choose at least one service category.';
    if (areas.isEmpty) return 'Choose at least one service area.';
    if (_isMissing(icFrontPath)) return 'Upload the front of your ID.';
    if (_isMissing(icBackPath)) return 'Upload the back of your ID.';
    if (_isMissing(selfiePath)) return 'Upload a verification selfie.';
    if (certificatePaths.length > 5) {
      return 'Choose no more than 5 certificates.';
    }
    if (workPhotoPaths.length > 6) return 'Choose no more than 6 work photos.';
    return null;
  }

  static bool _isMissing(String? value) =>
      value == null || value.trim().isEmpty;

  static ProviderApplicationDraft demo() => ProviderApplicationDraft(
        displayName: 'Ahmad Plumbing',
        bio: 'Friendly local plumbing service for homes and small shops.',
        categories: [serviceCategoryOptions.first, serviceCategoryOptions.last],
        areas: [serviceAreaOptions.first, serviceAreaOptions[1]],
        icFrontPath: 'demo/ic-front.jpg',
        icBackPath: 'demo/ic-back.jpg',
        selfiePath: 'demo/selfie.jpg',
        workPhotoPaths: const ['demo/work-1.jpg', 'demo/work-2.jpg'],
      );
}

class ProviderApplication {
  const ProviderApplication({
    required this.status,
    required this.displayName,
    required this.bio,
    required this.categories,
    required this.areas,
    required this.icFrontPath,
    required this.icBackPath,
    required this.selfiePath,
    required this.ssmPath,
    required this.certificatePaths,
    required this.workPhotoPaths,
    required this.adminNote,
    required this.submittedAt,
    required this.isAvailable,
    this.phone = '',
    this.whatsapp = '',
    this.categorySelections = const [],
    this.rating = 0,
    this.completedJobs = 0,
    this.avatarPath,
  });

  final ProviderApplicationStatus status;
  final String displayName;
  final String bio;
  final List<ServiceCategoryOption> categories;
  final List<ServiceAreaOption> areas;
  final String? icFrontPath;
  final String? icBackPath;
  final String? selfiePath;
  final String? ssmPath;
  final List<String> certificatePaths;
  final List<String> workPhotoPaths;
  final String? adminNote;
  final DateTime? submittedAt;
  final bool isAvailable;
  final String phone;
  final String whatsapp;
  final List<ProviderCategorySelection> categorySelections;
  final double rating;
  final int completedJobs;
  final String? avatarPath;

  factory ProviderApplication.demo({
    ProviderApplicationStatus status = ProviderApplicationStatus.approved,
    String displayName = 'Ahmad Plumbing',
    double rating = 4.9,
    int completedJobs = 86,
    String? avatarPath,
  }) =>
      ProviderApplication(
        status: status,
        displayName: displayName,
        bio: 'Friendly local plumbing service for homes and small shops.',
        categories: [serviceCategoryOptions.first, serviceCategoryOptions.last],
        areas: [serviceAreaOptions.first, serviceAreaOptions[1]],
        icFrontPath: 'demo/ic-front.jpg',
        icBackPath: 'demo/ic-back.jpg',
        selfiePath: 'demo/selfie.jpg',
        ssmPath: null,
        certificatePaths: const [],
        workPhotoPaths: const ['demo/work-1.jpg', 'demo/work-2.jpg'],
        adminNote: status == ProviderApplicationStatus.rejected
            ? 'Please upload a clearer ID image.'
            : null,
        submittedAt: DateTime(2026, 8, 1),
        isAvailable: status == ProviderApplicationStatus.approved,
        rating: rating,
        completedJobs: completedJobs,
        avatarPath: avatarPath,
        categorySelections: [
          for (final category in [
            serviceCategoryOptions.first,
            serviceCategoryOptions.last
          ])
            ProviderCategorySelection(
              category: category,
              status: ProviderCategoryStatus.approved,
              submittedAt: DateTime(2026, 8, 1),
            ),
        ],
      );
}
