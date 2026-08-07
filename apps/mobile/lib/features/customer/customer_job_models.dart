import '../../core/models/app_models.dart';
import '../../core/models/service_options.dart';

typedef JobCategoryOption = ServiceCategoryOption;
typedef JobAreaOption = ServiceAreaOption;

const jobCategoryOptions = serviceCategoryOptions;
const jobAreaOptions = serviceAreaOptions;

class JobDraft {
  const JobDraft({
    required this.category,
    required this.area,
    required this.title,
    required this.description,
    required this.fullAddress,
    required this.contactPhone,
    required this.contactWhatsapp,
    required this.budget,
    required this.timeWindow,
    this.scheduledAt,
    this.scheduledEndAt,
    required this.urgent,
    this.photoPaths = const [],
  });

  final JobCategoryOption category;
  final JobAreaOption area;
  final String title;
  final String description;
  final String fullAddress;
  final String contactPhone;
  final String contactWhatsapp;
  final String budget;
  final String timeWindow;
  final DateTime? scheduledAt;
  final DateTime? scheduledEndAt;
  final bool urgent;
  final List<String> photoPaths;

  double? get budgetAmount => double.tryParse(budget.trim());

  String? validate() {
    if (title.trim().length < 3) return 'Add a short job title.';
    if (description.trim().isEmpty) return 'Describe what needs to be done.';
    if (fullAddress.trim().isEmpty) return 'Add the full service address.';
    if (contactPhone.trim().isEmpty) return 'Add a contact phone number.';
    if (budgetAmount == null || budgetAmount! <= 0) {
      return 'Enter a budget greater than RM0.';
    }
    if (photoPaths.length > 5) return 'Choose no more than 5 photos.';
    if ((scheduledAt == null) != (scheduledEndAt == null)) {
      return 'Choose both a start and end time.';
    }
    if (scheduledAt != null) {
      final start = scheduledAt!;
      final end = scheduledEndAt!;
      final sameDay = start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      if (!sameDay || !end.isAfter(start)) {
        return 'End time must be later on the same day as the start time.';
      }
    }
    return null;
  }

  Job toPreviewJob() => Job(
        id: 'preview',
        title: title.trim().isEmpty ? 'Untitled job' : title.trim(),
        category: category.label,
        area: area.label,
        budget: budgetAmount ?? 0,
        time: timeWindow,
        scheduledAt: scheduledAt,
        scheduledEndAt: scheduledEndAt,
        status: JobStatus.draft,
        bidCount: 0,
        description: description.trim().isEmpty
            ? 'No description yet.'
            : description.trim(),
        urgent: urgent,
        categoryId: category.id,
        areaId: area.id,
        fullAddress: fullAddress,
        contactPhone: contactPhone,
        contactWhatsapp: contactWhatsapp,
        photoPaths: photoPaths,
      );

  static JobDraft demo() => JobDraft(
      category: jobCategoryOptions.first,
      area: jobAreaOptions.first,
      title: 'Fix leaking tap',
      description: 'Water is leaking from the kitchen tap.',
      fullAddress: '12 Example Street, Mount Austin, Johor Bahru',
      contactPhone: '+60 12 000 0101',
      contactWhatsapp: '+60 12 000 0101',
      budget: '100',
      timeWindow: 'Today, 2pm–6pm',
      urgent: false);
}
