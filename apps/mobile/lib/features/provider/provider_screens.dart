import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/data/fake_data.dart';
import '../../core/localization/app_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/models/service_options.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/image_validation.dart';
import '../../shared/widgets/app_widgets.dart';
import '../auth/auth_controller.dart';
import '../shell/shell_screen.dart';
import 'provider_application_controller.dart';
import 'provider_application_models.dart';
import 'provider_job_controller.dart';
import 'provider_job_models.dart';
import '../job_lifecycle/job_lifecycle_screens.dart';

class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() =>
      _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends ConsumerState<BecomeProviderScreen> {
  final displayNameController = TextEditingController();
  final bioController = TextEditingController();
  final imagePicker = ImagePicker();
  final selectedCategories = <ServiceCategoryOption>[];
  final selectedAreas = <ServiceAreaOption>[];
  String? icFrontPath;
  String? icBackPath;
  String? selfiePath;
  String? ssmPath;
  List<String> certificatePaths = const [];
  List<String> workPhotoPaths = const [];
  bool hydrated = false;

  @override
  void dispose() {
    displayNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _hydrate(ProviderApplication? application) {
    if (hydrated || application == null) return;
    hydrated = true;
    displayNameController.text = application.displayName;
    bioController.text = application.bio;
    selectedCategories.addAll(application.categories);
    selectedAreas.addAll(application.areas);
    icFrontPath = application.icFrontPath;
    icBackPath = application.icBackPath;
    selfiePath = application.selfiePath;
    ssmPath = application.ssmPath;
    certificatePaths = List<String>.from(application.certificatePaths);
    workPhotoPaths = List<String>.from(application.workPhotoPaths);
  }

  ProviderApplicationDraft _draft() => ProviderApplicationDraft(
        displayName: displayNameController.text,
        bio: bioController.text,
        categories: List.unmodifiable(selectedCategories),
        areas: List.unmodifiable(selectedAreas),
        icFrontPath: icFrontPath,
        icBackPath: icBackPath,
        selfiePath: selfiePath,
        ssmPath: ssmPath,
        certificatePaths: certificatePaths,
        workPhotoPaths: workPhotoPaths,
      );

  Future<void> _pickIdentity(String kind) async {
    final file = await imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (!mounted || file == null) return;
    final error = await ImageValidation.validatePath(file.path);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      if (kind == 'front') icFrontPath = file.path;
      if (kind == 'back') icBackPath = file.path;
      if (kind == 'selfie') selfiePath = file.path;
      if (kind == 'ssm') ssmPath = file.path;
    });
  }

  Future<void> _pickCertificates() async {
    final files =
        await imagePicker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (!mounted || files.isEmpty) return;
    final result = await ImageValidation.validatePaths(
        files.map((file) => file.path).toList(),
        maxCount: 5);
    if (!mounted) return;
    if (!result.isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    setState(() => certificatePaths = result.paths);
  }

  Future<void> _pickWorkPhotos() async {
    final files =
        await imagePicker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (!mounted || files.isEmpty) return;
    final result = await ImageValidation.validatePaths(
        files.map((file) => file.path).toList(),
        maxCount: 6);
    if (!mounted) return;
    if (!result.isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    setState(() => workPhotoPaths = result.paths);
  }

  Future<void> _submit() async {
    final application = await ref
        .read(providerApplicationControllerProvider.notifier)
        .submit(_draft());
    if (!mounted) return;
    if (application == null) {
      final error = ref.read(providerApplicationControllerProvider).error ??
          'Unable to submit your application.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go('/provider/verification');
  }

  void _toggleCategory(ServiceCategoryOption option, bool selected) =>
      setState(() {
        selectedCategories.removeWhere((item) => item.id == option.id);
        if (selected) selectedCategories.add(option);
      });

  void _toggleArea(ServiceAreaOption option, bool selected) => setState(() {
        selectedAreas.removeWhere((item) => item.id == option.id);
        if (selected) selectedAreas.add(option);
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerApplicationControllerProvider);
    _hydrate(state.application);
    final busy = state.isLoading;
    if (!state.initialized && state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [const LoadingSkeleton()],
      );
    }
    if (state.error != null && state.application == null && !hydrated) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ErrorState(
                onRetry: () => ref
                    .read(providerApplicationControllerProvider.notifier)
                    .load())
          ]);
    }
    if (state.status == ProviderApplicationStatus.pending ||
        state.status == ProviderApplicationStatus.approved ||
        state.status == ProviderApplicationStatus.suspended) {
      final approved = state.status == ProviderApplicationStatus.approved;
      final suspended = state.status == ProviderApplicationStatus.suspended;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            approved
                ? 'Provider approved'
                : (suspended
                    ? 'Provider access suspended'
                    : 'Application submitted'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            approved
                ? 'Your profile is ready for Provider Mode.'
                : (suspended
                    ? 'Provider features are temporarily unavailable. Contact support if you need help.'
                    : 'Your documents are waiting for admin review.'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    approved
                        ? Icons.verified_rounded
                        : (suspended
                            ? Icons.error_outline
                            : Icons.hourglass_top_rounded),
                    size: 34,
                    color: approved
                        ? AppColors.success
                        : (suspended ? AppColors.danger : AppColors.warning),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approved
                              ? 'Approved'
                              : (suspended ? 'Suspended' : 'Pending review'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          approved
                              ? 'Switch to Provider Mode from the top menu.'
                              : (suspended
                                  ? 'Your account needs support review before provider access can resume.'
                                  : 'We will notify you when an admin reviews the application.'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SecondaryButton(
            label: strings.business('view_verification_status'),
            onPressed: () => context.go('/provider/verification'),
          ),
        ],
      );
    }
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
              state.status == ProviderApplicationStatus.rejected
                  ? strings.business('update_provider_application')
                  : strings.business('become_provider'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(state.status == ProviderApplicationStatus.rejected
              ? 'Make the requested changes and submit again.'
              : 'Apply once and, after approval, switch between customer and provider modes.'),
          if (state.application?.adminNote != null) ...[
            const SizedBox(height: 14),
            Card(
                color: AppColors.danger.withValues(alpha: 0.08),
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('Admin note: ${state.application!.adminNote}',
                        style: const TextStyle(color: AppColors.danger))))
          ],
          const SizedBox(height: 22),
          TextField(
              controller: displayNameController,
              enabled: !busy,
              decoration: const InputDecoration(
                  labelText: 'Business or display name',
                  prefixIcon: Icon(Icons.storefront_outlined))),
          const SizedBox(height: 14),
          TextField(
              controller: bioController,
              enabled: !busy,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Tell customers about your work',
                  hintText:
                      'Experience, specialties, and what customers can expect.')),
          const SizedBox(height: 18),
          Text(strings.business('services'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in serviceCategoryOptions)
              FilterChip(
                  label: Text(option.label),
                  selected:
                      selectedCategories.any((item) => item.id == option.id),
                  onSelected: busy
                      ? null
                      : (selected) => _toggleCategory(option, selected))
          ]),
          const SizedBox(height: 18),
          Text(strings.business('service_areas'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in serviceAreaOptions)
              FilterChip(
                  label: Text(option.label),
                  selected: selectedAreas.any((item) => item.id == option.id),
                  onSelected:
                      busy ? null : (selected) => _toggleArea(option, selected))
          ]),
          const SizedBox(height: 22),
          Text(strings.business('verification_documents'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EvidenceTile(
              label: strings.business('id_front'),
              path: icFrontPath,
              required: true,
              onPick: busy ? null : () => _pickIdentity('front')),
          _EvidenceTile(
              label: strings.business('id_back'),
              path: icBackPath,
              required: true,
              onPick: busy ? null : () => _pickIdentity('back')),
          _EvidenceTile(
              label: strings.business('verification_selfie'),
              path: selfiePath,
              required: true,
              onPick: busy ? null : () => _pickIdentity('selfie')),
          _EvidenceTile(
              label: strings.business('business_document_optional'),
              path: ssmPath,
              onPick: busy ? null : () => _pickIdentity('ssm')),
          SecondaryButton(
              label: certificatePaths.isEmpty
                  ? 'Add certificates (optional)'
                  : '${certificatePaths.length} certificates selected',
              onPressed: busy ? null : _pickCertificates),
          const SizedBox(height: 14),
          Text(strings.business('work_photos'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          PhotoUploader(
              paths: workPhotoPaths, onPick: busy ? null : _pickWorkPhotos),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.danger))
          ],
          const SizedBox(height: 22),
          PrimaryButton(
              label: busy
                  ? strings.business('submitting')
                  : strings.business('submit_application'),
              onPressed: busy ? null : _submit),
        ]);
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile(
      {required this.label,
      required this.path,
      required this.onPick,
      this.required = false});

  final String label;
  final String? path;
  final VoidCallback? onPick;
  final bool required;

  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: Icon(
              path == null
                  ? Icons.upload_file_outlined
                  : Icons.check_circle_outline,
              color:
                  path == null ? AppColors.textSecondary : AppColors.success),
          title: Text(label),
          subtitle: Text(path == null
              ? (required ? 'Required' : 'Not added')
              : 'File selected'),
          trailing: OutlinedButton(
              onPressed: onPick,
              child: Text(path == null ? 'Choose' : 'Change'))));
}

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerApplicationControllerProvider);
    if (!state.initialized && state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [const LoadingSkeleton()],
      );
    }
    if (state.error != null && state.application == null) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ErrorState(
                onRetry: () => ref
                    .read(providerApplicationControllerProvider.notifier)
                    .load())
          ]);
    }
    final application = state.application;
    if (application == null) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(strings.business('verification_status'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            EmptyState(
                title: strings.business('no_application'),
                message: strings.business('complete_provider_apply')),
            PrimaryButton(
                label: strings.business('start_application'),
                onPressed: () => context.go('/provider/apply'))
          ]);
    }
    final status = application.status;
    final approved = status == ProviderApplicationStatus.approved;
    final rejected = status == ProviderApplicationStatus.rejected;
    final suspended = status == ProviderApplicationStatus.suspended;
    final color = approved
        ? AppColors.success
        : (rejected || suspended ? AppColors.danger : AppColors.warning);
    final icon = approved
        ? Icons.verified_rounded
        : (rejected || suspended
            ? Icons.error_outline
            : Icons.hourglass_top_rounded);
    final title = approved
        ? strings.business('approved')
        : (rejected
            ? strings.business('changes_requested')
            : (suspended
                ? strings.business('provider_access_suspended')
                : strings.business('pending_review')));
    final message = approved
        ? strings.business('provider_approved_message')
        : (rejected
            ? strings.business('resubmit_admin_note')
            : (suspended
                ? strings.business('provider_suspended_message')
                : strings.business('documents_pending_message')));
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(strings.business('verification_status'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Icon(icon, size: 34, color: color),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(message)
                        ])),
                    StatusBadge(label: status.name)
                  ]))),
          const SizedBox(height: 18),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(application.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                            '${application.categories.length} services · ${application.areas.length} service areas'),
                        Text(
                            '${application.workPhotoPaths.length} work photos · ${application.certificatePaths.length} certificates'),
                        if (application.submittedAt != null)
                          Text(
                              'Submitted ${application.submittedAt!.toLocal().toString().split('.').first}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        if (application.adminNote != null) ...[
                          const SizedBox(height: 12),
                          Text('Admin note: ${application.adminNote}',
                              style: const TextStyle(color: AppColors.danger))
                        ]
                      ]))),
          if (rejected) ...[
            const SizedBox(height: 18),
            SecondaryButton(
                label: strings.business('edit_resubmit'),
                onPressed: () => context.go('/provider/apply'))
          ],
          if (approved) ...[
            const SizedBox(height: 18),
            PrimaryButton(
                label: strings.business('open_provider_mode'),
                onPressed: () {
                  ref.read(appModeProvider.notifier).state = AppMode.provider;
                  context.go('/provider/feed');
                })
          ],
          const SizedBox(height: 12),
          const Text(
              'Identity documents are stored in a private bucket and are visible only to you and authorized admins.',
              style: TextStyle(color: AppColors.textSecondary))
        ]);
  }
}

class ProviderFeedScreen extends ConsumerWidget {
  const ProviderFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    if (!state.initialized && state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: const [
          LoadingSkeleton(),
          SizedBox(height: 12),
          LoadingSkeleton()
        ],
      );
    }
    if (state.error != null && state.jobs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          ErrorState(
              onRetry: () =>
                  ref.read(providerJobControllerProvider.notifier).loadFeed())
        ],
      );
    }
    final jobs = state.visibleJobs;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(providerJobControllerProvider.notifier).loadFeed(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PageHeader(
              title: strings.business('job_feed_title'),
              subtitle: strings.business('job_feed_subtitle')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${jobs.length} ${strings.business('jobs_available_suffix')}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/provider/filters'),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(strings.business('filters')),
                ),
              ],
            ),
          ),
          if (!state.filters.isDefault)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.filters.categoryLabel != null)
                    CategoryChip(label: state.filters.categoryLabel!),
                  if (state.filters.areaLabel != null)
                    AreaChip(label: state.filters.areaLabel!),
                  if (state.filters.urgentOnly)
                    StatusBadge(label: strings.business('urgent_only')),
                  if (state.filters.noBidsOnly)
                    StatusBadge(label: strings.business('no_bids_filter')),
                  StatusBadge(label: state.filters.sort.label),
                  TextButton(
                    onPressed: () => ref
                        .read(providerJobControllerProvider.notifier)
                        .clearFilters(),
                    child: Text(strings.business('clear')),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: EmptyState(
                title: strings.business('no_matching_jobs'),
                message: strings.business('try_another_filter'),
                icon: Icons.search_off_outlined,
              ),
            )
          else
            for (final job in jobs)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: JobCard(
                    job: job,
                    onTap: () => context.go('/provider/jobs/${job.id}')),
              ),
        ],
      ),
    );
  }
}

class ProviderFiltersScreen extends ConsumerStatefulWidget {
  const ProviderFiltersScreen({super.key});

  @override
  ConsumerState<ProviderFiltersScreen> createState() =>
      _ProviderFiltersScreenState();
}

class _ProviderFiltersScreenState extends ConsumerState<ProviderFiltersScreen> {
  late String? categoryId;
  late String? areaId;
  late DateTime? serviceDate;
  late bool urgentOnly;
  late bool noBidsOnly;
  late ProviderJobSort sort;
  late TextEditingController minBudgetController;
  late TextEditingController maxBudgetController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(providerJobControllerProvider).filters;
    categoryId = filters.categoryId;
    areaId = filters.areaId;
    serviceDate = filters.serviceDate;
    urgentOnly = filters.urgentOnly;
    noBidsOnly = filters.noBidsOnly;
    sort = filters.sort;
    minBudgetController = TextEditingController(
        text: filters.minBudget?.toStringAsFixed(0) ?? '');
    maxBudgetController = TextEditingController(
        text: filters.maxBudget?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    minBudgetController.dispose();
    maxBudgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: serviceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (selected != null) setState(() => serviceDate = selected);
  }

  Future<void> _apply() async {
    final min = double.tryParse(minBudgetController.text.trim());
    final max = double.tryParse(maxBudgetController.text.trim());
    if (minBudgetController.text.trim().isNotEmpty && min == null ||
        maxBudgetController.text.trim().isNotEmpty && max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid budget values.')));
      return;
    }
    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Minimum budget cannot exceed maximum budget.')));
      return;
    }
    final category = categoryId == null
        ? null
        : serviceCategoryOptions
            .firstWhere((option) => option.id == categoryId);
    final area = areaId == null
        ? null
        : serviceAreaOptions.firstWhere((option) => option.id == areaId);
    await ref.read(providerJobControllerProvider.notifier).setFilters(
          ProviderJobFilters(
            categoryId: category?.id,
            categoryLabel: category?.label,
            areaId: area?.id,
            areaLabel: area?.label,
            serviceDate: serviceDate,
            minBudget: min,
            maxBudget: max,
            urgentOnly: urgentOnly,
            noBidsOnly: noBidsOnly,
            sort: sort,
          ),
        );
    if (mounted) context.go('/provider/feed');
  }

  Future<void> _clear() async {
    setState(() {
      categoryId = null;
      areaId = null;
      serviceDate = null;
      urgentOnly = false;
      noBidsOnly = false;
      sort = ProviderJobSort.newest;
      minBudgetController.clear();
      maxBudgetController.clear();
    });
    await ref.read(providerJobControllerProvider.notifier).clearFilters();
    if (mounted) context.go('/provider/feed');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(strings.business('job_filters'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(strings.business('filters_hint')),
        const SizedBox(height: 22),
        Text(strings.business('category'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in serviceCategoryOptions)
              FilterChip(
                label: Text(option.label),
                selected: categoryId == option.id,
                onSelected: (selected) =>
                    setState(() => categoryId = selected ? option.id : null),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(strings.business('area'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in serviceAreaOptions)
              FilterChip(
                label: Text(option.label),
                selected: areaId == option.id,
                onSelected: (selected) =>
                    setState(() => areaId = selected ? option.id : null),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    controller: minBudgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: strings.business('min_budget'),
                        prefixText: 'RM '))),
            const SizedBox(width: 12),
            Expanded(
                child: TextFormField(
                    controller: maxBudgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: strings.business('max_budget'),
                        prefixText: 'RM '))),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined),
          title: Text(strings.business('service_date')),
          subtitle: Text(serviceDate == null
              ? 'Any date'
              : DateFormat('EEE, d MMM yyyy').format(serviceDate!)),
          trailing: TextButton(
              onPressed: serviceDate == null
                  ? null
                  : () => setState(() => serviceDate = null),
              child: Text(strings.business('clear'))),
          onTap: _pickDate,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: urgentOnly,
          onChanged: (value) => setState(() => urgentOnly = value),
          title: Text(strings.business('urgent_jobs_only')),
          subtitle: Text(strings.business('urgent_jobs_hint')),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: noBidsOnly,
          onChanged: (value) => setState(() => noBidsOnly = value),
          title: Text(strings.business('no_bids')),
          subtitle: Text(strings.business('first_offer_hint')),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ProviderJobSort>(
          initialValue: sort,
          decoration: InputDecoration(labelText: strings.business('sort_by')),
          items: [
            for (final option in ProviderJobSort.values)
              DropdownMenuItem(value: option, child: Text(option.label))
          ],
          onChanged: (value) =>
              setState(() => sort = value ?? ProviderJobSort.newest),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
            label: strings.business('apply_filters'), onPressed: _apply),
        const SizedBox(height: 10),
        SecondaryButton(
            label: strings.business('reset_filters'), onPressed: _clear),
      ],
    );
  }
}

class ProviderJobDetailScreen extends ConsumerWidget {
  const ProviderJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    Job? job;
    for (final candidate in state.jobs) {
      if (candidate.id == jobId) job = candidate;
    }
    if (job == null) {
      for (final candidate in fakeJobs) {
        if (candidate.id == jobId) job = candidate;
      }
    }
    if (job == null) {
      return EmptyState(
          title: strings.business('job_unavailable'),
          message: strings.business('job_expired_removed'),
          icon: Icons.work_off_outlined);
    }
    final selectedJob = job;
    ProviderBid? existingBid;
    for (final candidate in state.myBids) {
      if (candidate.bid.jobId == job.id &&
          (candidate.bid.status == BidStatus.pending ||
              candidate.bid.status == BidStatus.accepted)) {
        existingBid = candidate;
      }
    }
    final canEdit = existingBid?.bid.status == BidStatus.pending;
    final bidLabel = existingBid == null
        ? strings.business('submit_bid')
        : (canEdit
            ? strings.business('edit_bid')
            : strings.business('view_accepted_bid'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(job.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (job.urgent) StatusBadge(label: strings.business('urgent')),
          CategoryChip(label: job.category),
          AreaChip(label: job.area)
        ]),
        const SizedBox(height: 18),
        Text(job.description, style: Theme.of(context).textTheme.bodyLarge),
        if (job.photoPaths.isNotEmpty) ...[
          const SizedBox(height: 18),
          JobPhotoGallery(paths: job.photoPaths)
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.business('customer_budget'),
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('RM${job.budget.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(job.time),
                const SizedBox(height: 8),
                Text('${job.bidCount} offers received',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text(strings.business('address_protected')),
            subtitle: Text(strings.business('address_protected_message')),
          ),
        ),
        if (existingBid != null) ...[
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(
                  'Your bid: RM${existingBid.bid.amount.toStringAsFixed(0)}'),
              subtitle: Text('Available ${existingBid.bid.availableAt}'),
              trailing: StatusBadge(label: existingBid.bid.status.name),
            ),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: bidLabel,
          onPressed: existingBid?.bid.status == BidStatus.accepted
              ? () => context.go('/provider/bids')
              : () => context.go('/provider/jobs/${selectedJob.id}/bid',
                  extra: existingBid?.bid),
        ),
      ],
    );
  }
}

class SubmitBidScreen extends ConsumerStatefulWidget {
  const SubmitBidScreen({required this.jobId, super.key, this.existingBid});

  final String jobId;
  final Bid? existingBid;

  @override
  ConsumerState<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends ConsumerState<SubmitBidScreen> {
  final amountController = TextEditingController();
  final inclusionsController = TextEditingController();
  final exclusionsController = TextEditingController();
  final materialsController = TextEditingController();
  final messageController = TextEditingController();
  late DateTime availableAt;

  bool get locked => widget.existingBid?.status == BidStatus.accepted;

  @override
  void initState() {
    super.initState();
    final bid = widget.existingBid;
    availableAt =
        bid?.availableAtDate ?? DateTime.now().add(const Duration(hours: 2));
    amountController.text = bid?.amount.toStringAsFixed(0) ?? '';
    inclusionsController.text = bid?.inclusions ?? '';
    exclusionsController.text = bid?.exclusions ?? '';
    materialsController.text = bid?.materialsNote ?? '';
    messageController.text = bid?.message ?? '';
  }

  @override
  void dispose() {
    amountController.dispose();
    inclusionsController.dispose();
    exclusionsController.dispose();
    materialsController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAvailableAt() async {
    final date = await showDatePicker(
        context: context,
        initialDate: availableAt,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)));
    if (!mounted || date == null) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(availableAt));
    if (!mounted || time == null) return;
    setState(() => availableAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    final saved =
        await ref.read(providerJobControllerProvider.notifier).submitBid(
              BidDraft(
                bidId: widget.existingBid?.id,
                jobId: widget.jobId,
                amount: amountController.text,
                availableAt: availableAt,
                inclusions: inclusionsController.text,
                exclusions: exclusionsController.text,
                materialsNote: materialsController.text,
                message: messageController.text,
              ),
            );
    if (!mounted) return;
    if (saved == null) {
      final error = ref.read(providerJobControllerProvider).error ??
          'Unable to save your bid.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final strings = AppLocalizations(ref.read(appLanguageProvider));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(strings.business('bid_saved'))));
    context.go('/provider/bids');
  }

  Future<void> _withdraw() async {
    final bid = widget.existingBid;
    if (bid == null) return;
    final strings = AppLocalizations(ref.read(appLanguageProvider));
    final confirmed = await ConfirmationDialog.show(context,
        title: strings.business('withdraw_bid_title'),
        message: strings.business('withdraw_bid_message'));
    if (!confirmed || !mounted) return;
    final success = await ref
        .read(providerJobControllerProvider.notifier)
        .withdrawBid(bid.id);
    if (!mounted) return;
    if (success) context.go('/provider/bids');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    final busy = state.isSubmitting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
            widget.existingBid == null
                ? strings.business('submit_bid')
                : strings.business('edit_bid'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Job ${widget.jobId}',
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        BudgetInput(
            controller: amountController,
            label: strings.business('bid_amount')),
        const SizedBox(height: 14),
        DateTimeSelector(
            value: DateFormat('EEE, d MMM, h:mm a').format(availableAt),
            onTap: locked || busy ? null : _pickAvailableAt),
        const SizedBox(height: 14),
        TextField(
            controller: inclusionsController,
            enabled: !locked && !busy,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: strings.business('what_included'),
                hintText: 'Inspection and labour')),
        const SizedBox(height: 14),
        TextField(
            controller: exclusionsController,
            enabled: !locked && !busy,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: strings.business('what_excluded'),
                hintText: 'Materials and wall hacking')),
        const SizedBox(height: 14),
        TextField(
            controller: materialsController,
            enabled: !locked && !busy,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: strings.business('materials_note'),
                hintText: 'Materials are charged separately')),
        const SizedBox(height: 14),
        TextField(
            controller: messageController,
            enabled: !locked && !busy,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: strings.business('additional_note'))),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!, style: const TextStyle(color: AppColors.danger))
        ],
        const SizedBox(height: 22),
        if (!locked)
          PrimaryButton(
              label: busy
                  ? strings.business('saving')
                  : (widget.existingBid == null
                      ? strings.business('send_bid')
                      : strings.business('save_changes')),
              onPressed: busy ? null : _save),
        if (widget.existingBid?.status == BidStatus.pending) ...[
          const SizedBox(height: 10),
          SecondaryButton(
              label: busy
                  ? strings.business('working')
                  : strings.business('withdraw_bid'),
              onPressed: busy ? null : _withdraw),
        ],
        if (locked)
          Text(strings.business('accepted_bid_locked'),
              style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    if (!state.initialized && state.myBids.isEmpty) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: const [LoadingSkeleton()]);
    }
    if (state.error != null && state.myBids.isEmpty) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ErrorState(
                onRetry: () => ref
                    .read(providerJobControllerProvider.notifier)
                    .loadMyBids())
          ]);
    }
    if (state.myBids.isEmpty) {
      return ListView(children: [
        PageHeader(
            title: strings.business('my_bids_title'),
            subtitle: strings.business('my_bids_subtitle')),
        EmptyState(
            title: strings.business('no_bids'),
            message: strings.business('first_bid_message'),
            icon: Icons.request_quote_outlined)
      ]);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
            title: strings.business('my_bids_title'),
            subtitle: strings.business('my_bids_subtitle')),
        for (final item in state.myBids)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _MyBidCard(
              item: item,
              onEdit: item.bid.status == BidStatus.pending
                  ? () => context.go('/provider/jobs/${item.bid.jobId}/bid',
                      extra: item.bid)
                  : null,
              onWithdraw: item.bid.status == BidStatus.pending
                  ? () async {
                      final strings =
                          AppLocalizations(ref.read(appLanguageProvider));
                      final confirmed = await ConfirmationDialog.show(context,
                          title: strings.business('withdraw_bid_title'),
                          message: strings.business('withdraw_bid_message'));
                      if (confirmed && context.mounted) {
                        await ref
                            .read(providerJobControllerProvider.notifier)
                            .withdrawBid(item.bid.id);
                      }
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}

class _MyBidCard extends StatelessWidget {
  const _MyBidCard({required this.item, this.onEdit, this.onWithdraw});

  final ProviderBid item;
  final VoidCallback? onEdit;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final job = item.job;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(job?.title ?? 'Job ${item.bid.jobId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800))),
                StatusBadge(label: item.bid.status.name),
              ],
            ),
            const SizedBox(height: 6),
            if (job != null)
              Text(
                  '${job.area} · Customer budget RM${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('RM${item.bid.amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('Available ${item.bid.availableAt}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text('Includes: ${item.bid.inclusions}'),
            if (item.bid.exclusions.trim().isNotEmpty)
              Text('Excludes: ${item.bid.exclusions}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (item.bid.materialsNote?.trim().isNotEmpty ?? false)
              Text('Materials: ${item.bid.materialsNote}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (onEdit != null || onWithdraw != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                        child: OutlinedButton(
                            onPressed: onEdit, child: const Text('Edit bid'))),
                  if (onEdit != null && onWithdraw != null)
                    const SizedBox(width: 10),
                  if (onWithdraw != null)
                    Expanded(
                        child: OutlinedButton(
                            onPressed: onWithdraw,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Withdraw'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AssignedJobsScreen extends ConsumerWidget {
  const AssignedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    if (!state.initialized && state.isLoading && state.assignedJobs.isEmpty) {
      return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        PageHeader(
            title: strings.business('assigned_jobs_title'),
            subtitle: strings.business('assigned_jobs_subtitle')),
        const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: LoadingSkeleton())
      ]);
    }
    if (state.error != null && state.assignedJobs.isEmpty) {
      return ErrorState(
          onRetry: () => ref
              .read(providerJobControllerProvider.notifier)
              .loadAssignedJobs());
    }
    if (state.assignedJobs.isEmpty) {
      return EmptyState(
          title: strings.business('no_assigned_jobs'),
          message: strings.business('accepted_jobs_message'));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      PageHeader(
          title: strings.business('assigned_jobs_title'),
          subtitle: strings.business('assigned_jobs_subtitle')),
      for (final job in state.assignedJobs)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: JobCard(
                job: job,
                onTap: () => context.go('/provider/assigned/${job.id}')))
    ]);
  }
}

class AssignedJobDetailScreen extends ConsumerWidget {
  const AssignedJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(providerJobControllerProvider);
    Job? job;
    for (final candidate in state.assignedJobs) {
      if (candidate.id == jobId) {
        job = candidate;
        break;
      }
    }
    if (job == null && state.isLoading) {
      return const Padding(
          padding: EdgeInsets.all(20), child: LoadingSkeleton());
    }
    if (job == null) {
      return EmptyState(
          title: strings.business('assigned_job_not_found'),
          message: strings.business('accepted_provider_only'));
    }
    final assignedJob = job;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(assignedJob.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          StatusBadge(label: assignedJob.status.name),
          AreaChip(label: assignedJob.area)
        ]),
        const SizedBox(height: 18),
        Text(assignedJob.description),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFEAF5F3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.lock_open_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(strings.business('private_service_details'),
                    style: const TextStyle(fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 12),
              Text(assignedJob.fullAddress?.trim().isNotEmpty == true
                  ? assignedJob.fullAddress!
                  : strings.business('address_not_provided')),
              if (assignedJob.contactPhone?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Phone: ${assignedJob.contactPhone}')
              ],
              if (assignedJob.contactWhatsapp?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text('WhatsApp: ${assignedJob.contactWhatsapp}')
              ],
            ]),
          ),
        ),
        if (assignedJob.photoPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          JobPhotoGallery(paths: assignedJob.photoPaths)
        ],
        const SizedBox(height: 20),
        JobLifecycleActions(
            jobId: assignedJob.id,
            status: assignedJob.status,
            role: AppMode.provider,
            includeCancel: true),
        const SizedBox(height: 12),
        JobEventTimeline(jobId: assignedJob.id),
      ],
    );
  }
}

class ProviderProfileModeScreen extends ConsumerWidget {
  const ProviderProfileModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final applicationState = ref.watch(providerApplicationControllerProvider);
    final application = applicationState.application;
    final auth = ref.watch(authControllerProvider);
    if (application == null) {
      if (!applicationState.initialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return ErrorState(
          onRetry: () => ref.invalidate(providerApplicationControllerProvider));
    }
    final provider = ProviderProfile(
      id: auth.user?.id,
      name: application.displayName,
      category: application.categories.map((item) => item.label).join(', '),
      area: application.areas.map((item) => item.label).join(', '),
      rating: application.rating,
      completedJobs: application.completedJobs,
      bio: application.bio,
      verification: _verificationStatus(application.status),
      avatarPath: application.avatarPath,
      portfolioUrls: application.workPhotoPaths,
      isAvailable: application.isAvailable,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        PageHeader(
            title: strings.business('provider_profile'),
            subtitle: strings.business('provider_profile_subtitle')),
        ProviderCard(
          provider: provider,
          onTap: () => context.go('/provider/profile/edit'),
        ),
        if (provider.portfolioUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          PortfolioGallery(urls: provider.portfolioUrls),
        ],
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          value: application.isAvailable,
          onChanged: (value) async {
            final result = await ref
                .read(providerApplicationControllerProvider.notifier)
                .setAvailability(value);
            if (!context.mounted || result != null) return;
            final error = ref.read(providerApplicationControllerProvider).error;
            if (error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error)));
            }
          },
          title: Text(strings.business('available_new_jobs')),
          subtitle: Text(strings.business('show_matching_requests')),
        ),
        ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(strings.business('verification_status')),
            subtitle: Text(_verificationLabel(application.status)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/provider/verification')),
        if (applicationState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(applicationState.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ListTile(
            leading: const Icon(Icons.logout),
            title: Text(strings.business('sign_out')),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding');
            })
      ],
    );
  }

  static VerificationStatus _verificationStatus(
      ProviderApplicationStatus status) {
    switch (status) {
      case ProviderApplicationStatus.pending:
        return VerificationStatus.pending;
      case ProviderApplicationStatus.approved:
        return VerificationStatus.approved;
      case ProviderApplicationStatus.rejected:
        return VerificationStatus.rejected;
      case ProviderApplicationStatus.suspended:
        return VerificationStatus.suspended;
      case ProviderApplicationStatus.notApplied:
        return VerificationStatus.notApplied;
    }
  }

  static String _verificationLabel(ProviderApplicationStatus? status) {
    switch (status) {
      case ProviderApplicationStatus.approved:
        return 'Approved';
      case ProviderApplicationStatus.pending:
        return 'Pending review';
      case ProviderApplicationStatus.rejected:
        return 'Needs changes';
      case ProviderApplicationStatus.suspended:
        return 'Suspended';
      default:
        return 'Not applied';
    }
  }
}
