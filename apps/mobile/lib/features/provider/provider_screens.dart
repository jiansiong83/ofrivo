import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/fake_data.dart';
import '../../core/models/app_models.dart';
import '../../core/models/service_options.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../auth/auth_controller.dart';
import '../shell/shell_screen.dart';
import 'provider_application_controller.dart';
import 'provider_application_models.dart';

class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
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
    final file = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (!mounted || file == null) return;
    setState(() {
      if (kind == 'front') icFrontPath = file.path;
      if (kind == 'back') icBackPath = file.path;
      if (kind == 'selfie') selfiePath = file.path;
      if (kind == 'ssm') ssmPath = file.path;
    });
  }

  Future<void> _pickCertificates() async {
    final files = await imagePicker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (!mounted || files.isEmpty) return;
    setState(() => certificatePaths = files.take(5).map((file) => file.path).toList());
  }

  Future<void> _pickWorkPhotos() async {
    final files = await imagePicker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (!mounted || files.isEmpty) return;
    setState(() => workPhotoPaths = files.take(6).map((file) => file.path).toList());
  }

  Future<void> _submit() async {
    final application = await ref.read(providerApplicationControllerProvider.notifier).submit(_draft());
    if (!mounted) return;
    if (application == null) {
      final error = ref.read(providerApplicationControllerProvider).error ?? 'Unable to submit your application.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go('/provider/verification');
  }

  void _toggleCategory(ServiceCategoryOption option, bool selected) => setState(() {
        selectedCategories.removeWhere((item) => item.id == option.id);
        if (selected) selectedCategories.add(option);
      });

  void _toggleArea(ServiceAreaOption option, bool selected) => setState(() {
        selectedAreas.removeWhere((item) => item.id == option.id);
        if (selected) selectedAreas.add(option);
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerApplicationControllerProvider);
    _hydrate(state.application);
    final busy = state.isLoading;
    if (!state.initialized && state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [const LoadingSkeleton()],
      );
    }
    if (state.error != null && state.application == null && !hydrated) return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [ErrorState(onRetry: () => ref.read(providerApplicationControllerProvider.notifier).load())]);
    if (state.status == ProviderApplicationStatus.pending || state.status == ProviderApplicationStatus.approved || state.status == ProviderApplicationStatus.suspended) {
      final approved = state.status == ProviderApplicationStatus.approved;
      final suspended = state.status == ProviderApplicationStatus.suspended;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            approved ? 'Provider approved' : (suspended ? 'Provider access suspended' : 'Application submitted'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
                        : (suspended ? Icons.error_outline : Icons.hourglass_top_rounded),
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
                          approved ? 'Approved' : (suspended ? 'Suspended' : 'Pending review'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
            label: 'View verification status',
            onPressed: () => context.go('/provider/verification'),
          ),
        ],
      );
    }
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
      Text(state.status == ProviderApplicationStatus.rejected ? 'Update your provider application' : 'Become a provider', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(state.status == ProviderApplicationStatus.rejected ? 'Make the requested changes and submit again.' : 'Apply once and, after approval, switch between customer and provider modes.'),
      if (state.application?.adminNote != null) ...[const SizedBox(height: 14), Card(color: AppColors.danger.withValues(alpha: 0.08), child: Padding(padding: const EdgeInsets.all(14), child: Text('Admin note: ${state.application!.adminNote}', style: const TextStyle(color: AppColors.danger))))],
      const SizedBox(height: 22),
      TextField(controller: displayNameController, enabled: !busy, decoration: const InputDecoration(labelText: 'Business or display name', prefixIcon: Icon(Icons.storefront_outlined))),
      const SizedBox(height: 14),
      TextField(controller: bioController, enabled: !busy, maxLines: 4, decoration: const InputDecoration(labelText: 'Tell customers about your work', hintText: 'Experience, specialties, and what customers can expect.')),
      const SizedBox(height: 18),
      const Text('Services', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final option in serviceCategoryOptions) FilterChip(label: Text(option.label), selected: selectedCategories.any((item) => item.id == option.id), onSelected: busy ? null : (selected) => _toggleCategory(option, selected))]),
      const SizedBox(height: 18),
      const Text('Service areas', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final option in serviceAreaOptions) FilterChip(label: Text(option.label), selected: selectedAreas.any((item) => item.id == option.id), onSelected: busy ? null : (selected) => _toggleArea(option, selected))]),
      const SizedBox(height: 22),
      const Text('Verification documents', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _EvidenceTile(label: 'ID front', path: icFrontPath, required: true, onPick: busy ? null : () => _pickIdentity('front')),
      _EvidenceTile(label: 'ID back', path: icBackPath, required: true, onPick: busy ? null : () => _pickIdentity('back')),
      _EvidenceTile(label: 'Verification selfie', path: selfiePath, required: true, onPick: busy ? null : () => _pickIdentity('selfie')),
      _EvidenceTile(label: 'SSM / business document (optional)', path: ssmPath, onPick: busy ? null : () => _pickIdentity('ssm')),
      SecondaryButton(label: certificatePaths.isEmpty ? 'Add certificates (optional)' : '${certificatePaths.length} certificates selected', onPressed: busy ? null : _pickCertificates),
      const SizedBox(height: 14),
      const Text('Work photos', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      PhotoUploader(paths: workPhotoPaths, onPick: busy ? null : _pickWorkPhotos),
      if (state.error != null) ...[const SizedBox(height: 12), Text(state.error!, style: const TextStyle(color: AppColors.danger))],
      const SizedBox(height: 22),
      PrimaryButton(label: busy ? 'Submitting…' : 'Submit application', onPressed: busy ? null : _submit),
    ]);
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.label, required this.path, required this.onPick, this.required = false});

  final String label;
  final String? path;
  final VoidCallback? onPick;
  final bool required;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(path == null ? Icons.upload_file_outlined : Icons.check_circle_outline, color: path == null ? AppColors.textSecondary : AppColors.success), title: Text(label), subtitle: Text(path == null ? (required ? 'Required' : 'Not added') : 'File selected'), trailing: OutlinedButton(onPressed: onPick, child: Text(path == null ? 'Choose' : 'Change'))));
}

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerApplicationControllerProvider);
    if (!state.initialized && state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [const LoadingSkeleton()],
      );
    }
    if (state.error != null && state.application == null) return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [ErrorState(onRetry: () => ref.read(providerApplicationControllerProvider.notifier).load())]);
    final application = state.application;
    if (application == null) return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Verification status', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), const EmptyState(title: 'No application yet', message: 'Complete your provider information and verification documents to apply.'), PrimaryButton(label: 'Start application', onPressed: () => context.go('/provider/apply'))]);
    final status = application.status;
    final approved = status == ProviderApplicationStatus.approved;
    final rejected = status == ProviderApplicationStatus.rejected;
    final suspended = status == ProviderApplicationStatus.suspended;
    final color = approved ? AppColors.success : (rejected || suspended ? AppColors.danger : AppColors.warning);
    final icon = approved ? Icons.verified_rounded : (rejected || suspended ? Icons.error_outline : Icons.hourglass_top_rounded);
    final title = approved ? 'Approved' : (rejected ? 'Changes requested' : (suspended ? 'Provider access suspended' : 'Pending review'));
    final message = approved ? 'Your provider profile is approved. You can switch to Provider Mode.' : (rejected ? 'Update the application using the admin note below and submit again.' : (suspended ? 'Provider features are temporarily unavailable. Contact support if you need help.' : 'Your documents are waiting for an admin review.'));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Verification status', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon, size: 34, color: color), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 4), Text(message)])), StatusBadge(label: status.name)]))), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(application.displayName, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('${application.categories.length} services · ${application.areas.length} service areas'), Text('${application.workPhotoPaths.length} work photos · ${application.certificatePaths.length} certificates'), if (application.submittedAt != null) Text('Submitted ${application.submittedAt!.toLocal().toString().split('.').first}', style: const TextStyle(color: AppColors.textSecondary)), if (application.adminNote != null) ...[const SizedBox(height: 12), Text('Admin note: ${application.adminNote}', style: const TextStyle(color: AppColors.danger))]]))), if (rejected) ...[const SizedBox(height: 18), SecondaryButton(label: 'Edit and resubmit', onPressed: () => context.go('/provider/apply'))], if (approved) ...[const SizedBox(height: 18), PrimaryButton(label: 'Open Provider Mode', onPressed: () { ref.read(appModeProvider.notifier).state = AppMode.provider; context.go('/provider/feed'); })], const SizedBox(height: 12), const Text('Identity documents are stored in a private bucket and are visible only to you and authorized admins.', style: TextStyle(color: AppColors.textSecondary))]);
  }
}

class ProviderFeedScreen extends ConsumerWidget {
  const ProviderFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(fakeJobsProvider).where((job) => job.status == JobStatus.open).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [const PageHeader(title: 'Job feed', subtitle: 'Open requests near your selected service areas.'), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Expanded(child: Text('${jobs.length} jobs available', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), OutlinedButton.icon(onPressed: () => context.go('/provider/filters'), icon: const Icon(Icons.tune, size: 18), label: const Text('Filters'))])), const SizedBox(height: 14), for (final job in jobs) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: JobCard(job: job, onTap: () => context.go('/provider/jobs/${job.id}')))]);
  }
}

class ProviderFiltersScreen extends StatelessWidget {
  const ProviderFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Job filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(label: 'Plumbing'), CategoryChip(label: 'Electrical'), CategoryChip(label: 'Cleaning'), CategoryChip(label: 'Handyman')]), const SizedBox(height: 18), const Text('Area', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Wrap(spacing: 8, children: [AreaChip(label: 'Mount Austin'), AreaChip(label: 'Taman Molek'), AreaChip(label: 'Permas Jaya')]), const SizedBox(height: 18), SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Urgent jobs only')), const SizedBox(height: 14), PrimaryButton(label: 'Apply filters', onPressed: () => context.go('/provider/feed'))]);
}

class ProviderJobDetailScreen extends ConsumerWidget {
  const ProviderJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(fakeJobsProvider).firstWhere((item) => item.id == jobId, orElse: () => fakeJobs.first);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text(job.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10), Wrap(spacing: 8, children: [if (job.urgent) const StatusBadge(label: 'Urgent'), CategoryChip(label: job.category), AreaChip(label: job.area)]), const SizedBox(height: 18), Text(job.description, style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Customer budget', style: TextStyle(color: AppColors.textSecondary)), Text('RM${job.budget.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(job.time), const SizedBox(height: 8), Text('${job.bidCount} offers received', style: const TextStyle(color: AppColors.textSecondary))]))), const SizedBox(height: 18), const Text('Exact address and contact details stay hidden until a bid is accepted.', style: TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 18), PrimaryButton(label: 'Submit a bid', onPressed: () => context.go('/provider/jobs/${job.id}/bid'))]);
  }
}

class SubmitBidScreen extends StatefulWidget {
  const SubmitBidScreen({required this.jobId, super.key});

  final String jobId;

  @override
  State<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends State<SubmitBidScreen> {
  final amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Submit a bid', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Job ${widget.jobId}', style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 20), BudgetInput(controller: amountController), const SizedBox(height: 14), const DateTimeSelector(value: 'Today, 5pm'), const SizedBox(height: 14), const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'What is included?', hintText: 'Inspection and labour')), const SizedBox(height: 14), const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'What is excluded?', hintText: 'Materials and wall hacking')), const SizedBox(height: 14), const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Additional note')), const SizedBox(height: 22), PrimaryButton(label: 'Send bid', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake-data flow: bid submitted.'))); context.go('/provider/bids'); })]);
}

class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bids = ref.watch(fakeBidsProvider);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [const PageHeader(title: 'My bids', subtitle: 'Keep track of your pending and accepted offers.'), for (final bid in bids) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: BidCard(bid: bid))]);
  }
}

class AssignedJobsScreen extends ConsumerWidget {
  const AssignedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(fakeJobsProvider).where((job) => job.status == JobStatus.assigned || job.status == JobStatus.inProgress).toList();
    if (jobs.isEmpty) return const EmptyState(title: 'No assigned jobs', message: 'Accepted bids will appear here.');
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [const PageHeader(title: 'Assigned jobs', subtitle: 'Your accepted work and next actions.'), for (final job in jobs) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: JobCard(job: job, onTap: () => context.go('/provider/assigned/${job.id}')))]);
  }
}

class AssignedJobDetailScreen extends ConsumerWidget {
  const AssignedJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Assigned job', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 16), const StatusBadge(label: 'assigned'), const SizedBox(height: 18), const Text('Full address and contact are visible in this fake-data assigned state.', style: TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Job ID: $jobId', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('12 Example Street, Johor Bahru'), const Text('+60 12 345 6789')]))), const SizedBox(height: 20), PrimaryButton(label: 'Mark as started', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake-data flow: start_job placeholder.')))), const SizedBox(height: 10), SecondaryButton(label: 'Mark as completed', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake-data flow: complete_job placeholder.'))))]);
}

class ProviderProfileModeScreen extends ConsumerWidget {
  const ProviderProfileModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(providerProfileProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [const PageHeader(title: 'Provider profile', subtitle: 'Your public profile and availability.'), ProviderCard(provider: provider), const SizedBox(height: 16), SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Available for new jobs'), subtitle: const Text('Show matching requests in your feed')), ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('Verification status'), subtitle: const Text('Approved'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/provider/verification')), ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: () async { await ref.read(authControllerProvider.notifier).signOut(); if (context.mounted) context.go('/onboarding'); })]);
  }
}
