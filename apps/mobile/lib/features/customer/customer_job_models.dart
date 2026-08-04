import '../../core/models/app_models.dart';

class JobCategoryOption {
  const JobCategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}
class JobAreaOption {
  const JobAreaOption({required this.id, required this.label});

  final String id;
  final String label;
}

const jobCategoryOptions = <JobCategoryOption>[
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000201', label: 'Plumbing / Toilet'),
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000202', label: 'Electrical / Lighting / Fan'),
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000203', label: 'Air Conditioning'),
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000204', label: 'Moving / Delivery'),
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000205', label: 'Cleaning'),
  JobCategoryOption(id: '00000000-0000-0000-0000-000000000206', label: 'Handyman'),
];

const jobAreaOptions = <JobAreaOption>[
  JobAreaOption(id: '00000000-0000-0000-0000-000000000251', label: 'Mount Austin'),
  JobAreaOption(id: '00000000-0000-0000-0000-000000000252', label: 'Taman Molek'),
  JobAreaOption(id: '00000000-0000-0000-0000-000000000253', label: 'Permas Jaya'),
  JobAreaOption(id: '00000000-0000-0000-0000-000000000254', label: 'Skudai'),
];

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
  final bool urgent;
  final List<String> photoPaths;

  double? get budgetAmount => double.tryParse(budget.trim());

  String? validate() {
    if (title.trim().length < 3) return 'Add a short job title.';
    if (description.trim().isEmpty) return 'Describe what needs to be done.';
    if (fullAddress.trim().isEmpty) return 'Add the full service address.';
    if (contactPhone.trim().isEmpty) return 'Add a contact phone number.';
    if (budgetAmount == null || budgetAmount! <= 0) return 'Enter a budget greater than RM0.';
    if (photoPaths.length > 5) return 'Choose no more than 5 photos.';
    return null;
  }

  Job toPreviewJob() => Job(
        id: 'preview',
        title: title.trim().isEmpty ? 'Untitled job' : title.trim(),
        category: category.label,
        area: area.label,
        budget: budgetAmount ?? 0,
        time: timeWindow,
        status: JobStatus.draft,
        bidCount: 0,
        description: description.trim().isEmpty ? 'No description yet.' : description.trim(),
        urgent: urgent,
        categoryId: category.id,
        areaId: area.id,
        fullAddress: fullAddress,
        contactPhone: contactPhone,
        contactWhatsapp: contactWhatsapp,
        photoPaths: photoPaths,
      );

  static JobDraft demo() => JobDraft(category: jobCategoryOptions.first, area: jobAreaOptions.first, title: 'Fix leaking tap', description: 'Water is leaking from the kitchen tap.', fullAddress: '12 Example Street, Mount Austin, Johor Bahru', contactPhone: '+60 12 000 0101', contactWhatsapp: '+60 12 000 0101', budget: '100', timeWindow: 'Today, 2pm–6pm', urgent: false);
}
