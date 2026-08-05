import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/app_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/image_validation.dart';
import '../auth/auth_controller.dart';
import '../shell/shell_screen.dart';
import '../../shared/widgets/app_widgets.dart';
import 'customer_job_models.dart';
import 'customer_jobs_controller.dart';
import 'customer_bid_controller.dart';
import 'customer_bid_models.dart';
import '../job_lifecycle/job_lifecycle_screens.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final jobsState = ref.watch(customerJobsControllerProvider);
    final jobs = jobsState.jobs;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
            title: strings.business('good_morning'),
            subtitle: strings.business('customer_home_subtitle')),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PrimaryButton(
                label: strings.business('post_new_job'),
                icon: Icons.add,
                onPressed: () => context.go('/customer/post'))),
        const SizedBox(height: 22),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(strings.business('active_jobs'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
        if (!jobsState.initialized && jobsState.isLoading)
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LoadingSkeleton())
        else if (jobsState.error != null && jobs.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ErrorState(
                  onRetry: () =>
                      ref.read(customerJobsControllerProvider.notifier).load()))
        else if (jobs.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EmptyState(
                  title: strings.business('no_jobs_yet'),
                  message: strings.business('first_request')))
        else
          for (final job in jobs.take(2))
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: JobCard(
                    job: job,
                    onTap: () => context.go('/customer/jobs/${job.id}'))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(strings.business('privacy_provider')))
                    ])))),
      ],
    );
  }
}

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final budgetController = TextEditingController();
  final timeController = TextEditingController(text: 'Today, 2pm–6pm');
  final imagePicker = ImagePicker();

  JobCategoryOption selectedCategory = jobCategoryOptions.first;
  JobAreaOption selectedArea = jobAreaOptions.first;
  bool urgent = false;
  List<String> photoPaths = const [];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    budgetController.dispose();
    timeController.dispose();
    super.dispose();
  }

  JobDraft _draft() => JobDraft(
        category: selectedCategory,
        area: selectedArea,
        title: titleController.text,
        description: descriptionController.text,
        fullAddress: addressController.text,
        contactPhone: phoneController.text,
        contactWhatsapp: whatsappController.text,
        budget: budgetController.text,
        timeWindow: timeController.text,
        urgent: urgent,
        photoPaths: photoPaths,
      );

  Future<void> _pickPhotos() async {
    final files =
        await imagePicker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
    if (!mounted || files.isEmpty) return;
    final result = await ImageValidation.validatePaths(
        files.map((file) => file.path).toList(),
        maxCount: 5);
    if (!mounted) return;
    if (!result.isValid) {
      _showValidation(result.error!);
      return;
    }
    setState(() => photoPaths = result.paths);
  }

  void _showValidation(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  void _preview() {
    final draft = _draft();
    final error = draft.validate();
    if (error != null) {
      _showValidation(error);
      return;
    }
    context.push('/customer/post/preview', extra: draft);
  }

  Future<void> _saveDraft() async {
    final job = await ref
        .read(customerJobsControllerProvider.notifier)
        .saveDraft(_draft());
    if (!mounted) return;
    if (job == null) {
      _showValidation(ref.read(customerJobsControllerProvider).error ??
          'Unable to save this draft.');
      return;
    }
    final strings = AppLocalizations(ref.read(appLanguageProvider));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(strings.business('draft_saved'))));
    context.go('/customer/jobs');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final jobsState = ref.watch(customerJobsControllerProvider);
    final busy = jobsState.isLoading;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(strings.business('post_job_title'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(strings.business('post_job_hint'),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 22),
        DropdownButtonFormField<JobCategoryOption>(
          initialValue: selectedCategory,
          decoration: InputDecoration(
              labelText: strings.business('service_category'),
              prefixIcon: const Icon(Icons.category_outlined)),
          items: [
            for (final option in jobCategoryOptions)
              DropdownMenuItem(value: option, child: Text(option.label))
          ],
          onChanged: busy
              ? null
              : (value) {
                  if (value != null) setState(() => selectedCategory = value);
                },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<JobAreaOption>(
          initialValue: selectedArea,
          decoration: InputDecoration(
              labelText: strings.business('area'),
              prefixIcon: const Icon(Icons.location_on_outlined)),
          items: [
            for (final option in jobAreaOptions)
              DropdownMenuItem(value: option, child: Text(option.label))
          ],
          onChanged: busy
              ? null
              : (value) {
                  if (value != null) setState(() => selectedArea = value);
                },
        ),
        const SizedBox(height: 14),
        TextField(
            controller: titleController,
            enabled: !busy,
            decoration: InputDecoration(
                labelText: strings.business('job_title'),
                hintText: 'e.g. Fix leaking tap')),
        const SizedBox(height: 14),
        TextField(
            controller: descriptionController,
            enabled: !busy,
            maxLines: 4,
            decoration: InputDecoration(
                labelText: strings.business('job_description'),
                hintText: 'What should the provider inspect or repair?')),
        const SizedBox(height: 14),
        TextField(
            controller: addressController,
            enabled: !busy,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: strings.business('full_address'),
                prefixIcon: const Icon(Icons.home_outlined),
                hintText: 'Visible only to the selected provider')),
        const SizedBox(height: 14),
        TextField(
            controller: phoneController,
            enabled: !busy,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: strings.business('contact_phone'),
                prefixIcon: const Icon(Icons.phone_outlined))),
        const SizedBox(height: 14),
        TextField(
            controller: whatsappController,
            enabled: !busy,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: '${strings.business('whatsapp')} (optional)',
                prefixIcon: const Icon(Icons.chat_outlined))),
        const SizedBox(height: 14),
        BudgetInput(controller: budgetController),
        const SizedBox(height: 8),
        TextField(
            controller: timeController,
            enabled: !busy,
            decoration: InputDecoration(
                labelText: strings.business('time_window'),
                prefixIcon: const Icon(Icons.schedule_outlined),
                hintText: 'e.g. Today, 2pm–6pm')),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.business('mark_urgent')),
            subtitle: const Text(
                'Urgent requests are highlighted to approved providers.'),
            value: urgent,
            onChanged: busy ? null : (value) => setState(() => urgent = value)),
        PhotoUploader(paths: photoPaths, onPick: busy ? null : _pickPhotos),
        if (jobsState.error != null) ...[
          const SizedBox(height: 12),
          Text(jobsState.error!,
              style: const TextStyle(color: AppColors.danger))
        ],
        const SizedBox(height: 22),
        PrimaryButton(
            label: busy
                ? strings.business('saving')
                : strings.business('preview_job'),
            onPressed: busy ? null : _preview),
        const SizedBox(height: 10),
        SecondaryButton(
            label: strings.business('save_draft'),
            onPressed: busy ? null : _saveDraft),
      ],
    );
  }
}

class PostJobPreviewScreen extends ConsumerWidget {
  const PostJobPreviewScreen({required this.draft, super.key});

  final JobDraft draft;

  Future<void> _submit(BuildContext context, WidgetRef ref,
      {required bool publish}) async {
    final strings = AppLocalizations(ref.read(appLanguageProvider));
    final controller = ref.read(customerJobsControllerProvider.notifier);
    final job = publish
        ? await controller.publish(draft)
        : await controller.saveDraft(draft);
    if (!context.mounted) return;
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(customerJobsControllerProvider).error ??
              'Unable to save this job.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(publish
            ? strings.business('job_published')
            : strings.business('draft_saved'))));
    context.go('/customer/jobs');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(customerJobsControllerProvider);
    final preview = draft.toPreviewJob();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(strings.business('preview_job'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(strings.business('review_before_share'),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        JobCard(job: preview),
        const SizedBox(height: 12),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.business('private_contact'),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(draft.fullAddress),
                      Text(draft.contactPhone),
                      if (draft.contactWhatsapp.trim().isNotEmpty)
                        Text('WhatsApp: ${draft.contactWhatsapp}'),
                      if (draft.photoPaths.isNotEmpty)
                        Text('${draft.photoPaths.length} photo(s) attached',
                            style:
                                const TextStyle(color: AppColors.textSecondary))
                    ]))),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!, style: const TextStyle(color: AppColors.danger))
        ],
        const SizedBox(height: 18),
        PrimaryButton(
            label: state.isLoading
                ? strings.business('saving')
                : strings.business('publish_job'),
            onPressed: state.isLoading
                ? null
                : () => _submit(context, ref, publish: true)),
        const SizedBox(height: 10),
        SecondaryButton(
            label: strings.business('save_draft'),
            onPressed: state.isLoading
                ? null
                : () => _submit(context, ref, publish: false)),
        const SizedBox(height: 10),
        TextButton(
            onPressed: state.isLoading ? null : () => context.pop(),
            child: Text(strings.business('keep_editing'))),
      ],
    );
  }
}

class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(customerJobsControllerProvider);
    if (!state.initialized && state.isLoading) {
      return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        PageHeader(
            title: strings.business('my_jobs_title'),
            subtitle: strings.business('track_jobs')),
        const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: LoadingSkeleton())
      ]);
    }
    if (state.error != null && state.jobs.isEmpty) {
      return ListView(children: [
        PageHeader(
            title: strings.business('my_jobs_title'),
            subtitle: strings.business('track_jobs')),
        ErrorState(
            onRetry: () =>
                ref.read(customerJobsControllerProvider.notifier).load())
      ]);
    }
    if (state.jobs.isEmpty) {
      return ListView(children: [
        PageHeader(
            title: strings.business('my_jobs_title'),
            subtitle: strings.business('track_jobs')),
        EmptyState(
            title: strings.business('no_jobs_yet'),
            message: strings.business('post_request_here'))
      ]);
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      PageHeader(
          title: strings.business('my_jobs_title'),
          subtitle: strings.business('track_jobs')),
      for (final job in state.jobs)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: JobCard(
                job: job, onTap: () => context.go('/customer/jobs/${job.id}')))
    ]);
  }
}

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(customerJobsControllerProvider);
    if (!state.initialized && state.isLoading) {
      return const Padding(
          padding: EdgeInsets.all(20), child: LoadingSkeleton());
    }
    Job? job;
    for (final candidate in state.jobs) {
      if (candidate.id == jobId) {
        job = candidate;
        break;
      }
    }
    if (job == null) {
      return EmptyState(
          title: strings.business('job_not_found'),
          message: strings.business('job_removed'));
    }
    final currentJob = job;
    final canCancel = currentJob.status == JobStatus.open ||
        currentJob.status == JobStatus.assigned ||
        currentJob.status == JobStatus.inProgress;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(currentJob.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            StatusBadge(label: currentJob.status.name),
            AreaChip(label: currentJob.area)
          ]),
          const SizedBox(height: 18),
          Text(currentJob.description,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.business('budget_label'),
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        Text('RM${currentJob.budget.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                        const SizedBox(height: 12),
                        Text(currentJob.time),
                        if (currentJob.fullAddress?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 12),
                          Text(strings.business('service_address'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          Text(currentJob.fullAddress!)
                        ],
                        if (currentJob.contactPhone?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 12),
                          Text(strings.business('contact'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          Text(currentJob.contactPhone!)
                        ]
                      ]))),
          const SizedBox(height: 18),
          PrimaryButton(
              label:
                  '${currentJob.bidCount} ${strings.business('offers_received_suffix')}',
              onPressed: () =>
                  context.go('/customer/jobs/${currentJob.id}/bids')),
          const SizedBox(height: 10),
          DangerButton(
              label: canCancel
                  ? strings.business('cancel_job')
                  : strings.business('cancel_job_cannot'),
              onPressed: canCancel
                  ? () async {
                      final confirmed = await ConfirmationDialog.show(context,
                          title: strings.business('cancel_job_title'),
                          message: strings.business('cancel_job_message'));
                      if (!confirmed || !context.mounted) return;
                      final cancelled = await ref
                          .read(customerJobsControllerProvider.notifier)
                          .cancel(currentJob.id);
                      if (!context.mounted) return;
                      if (cancelled) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(strings.business('job_cancelled'))));
                        context.go('/customer/jobs');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ref
                                    .read(customerJobsControllerProvider)
                                    .error ??
                                'Unable to cancel this job.')));
                      }
                    }
                  : null),
          JobLifecycleActions(
              jobId: currentJob.id,
              status: currentJob.status,
              role: AppMode.customer),
          if (currentJob.status != JobStatus.open &&
              currentJob.status != JobStatus.draft) ...[
            const SizedBox(height: 12),
            JobEventTimeline(jobId: currentJob.id)
          ],
        ]);
  }
}

class ReceivedBidsScreen extends ConsumerWidget {
  const ReceivedBidsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final state = ref.watch(customerBidControllerProvider(jobId));
    if (!state.initialized && state.isLoading) {
      return const Padding(
          padding: EdgeInsets.all(20), child: LoadingSkeleton());
    }
    if (state.error != null && state.bids.isEmpty) {
      return ErrorState(
          onRetry: () => ref
              .read(customerBidControllerProvider(jobId).notifier)
              .load(jobId));
    }
    if (state.bids.isEmpty) {
      return EmptyState(
          title: strings.business('no_bids'),
          message: strings.business('no_bids_message'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(strings.business('received_bids'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
            '${state.bids.length} ${strings.business('providers_responded_suffix')}',
            style: const TextStyle(color: AppColors.textSecondary)),
        if (state.info != null) ...[
          const SizedBox(height: 14),
          Card(
              color: const Color(0xFFEAF5F3),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.lock_open_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.info!))
                  ]))),
        ],
        const SizedBox(height: 18),
        for (final offer in state.bids)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CustomerBidOfferCard(
              offer: offer,
              isAccepting: state.isAccepting,
              onProviderTap: () => context.go(
                  '/customer/providers/${offer.provider.id ?? offer.bid.providerId ?? offer.bid.id}',
                  extra: offer.provider),
              onAccept: offer.bid.status == BidStatus.pending
                  ? () async {
                      final confirmed = await ConfirmationDialog.show(context,
                          title: strings.business('accept_offer_title'),
                          message: strings.business('accept_offer_message'));
                      if (!confirmed || !context.mounted) return;
                      final accepted = await ref
                          .read(customerBidControllerProvider(jobId).notifier)
                          .accept(jobId, offer.bid.id);
                      if (!context.mounted || accepted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ref
                                  .read(customerBidControllerProvider(jobId))
                                  .error ??
                              'Unable to accept this offer.')));
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}

class _CustomerBidOfferCard extends ConsumerWidget {
  const _CustomerBidOfferCard(
      {required this.offer,
      required this.isAccepting,
      this.onProviderTap,
      this.onAccept});

  final CustomerBidOffer offer;
  final bool isAccepting;
  final VoidCallback? onProviderTap;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final bid = offer.bid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
              onTap: onProviderTap,
              borderRadius: BorderRadius.circular(12),
              child: ProviderCard(provider: offer.provider)),
          const SizedBox(height: 12),
          Row(children: [
            Text('RM${bid.amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
            const Spacer(),
            StatusBadge(label: bid.status.name)
          ]),
          const SizedBox(height: 8),
          Text('Available ${bid.availableAt}'),
          const SizedBox(height: 8),
          Text('Includes: ${bid.inclusions}'),
          if (bid.exclusions.trim().isNotEmpty)
            Text('Excludes: ${bid.exclusions}',
                style: Theme.of(context).textTheme.bodySmall),
          if (bid.materialsNote?.trim().isNotEmpty ?? false)
            Text('Materials: ${bid.materialsNote}',
                style: Theme.of(context).textTheme.bodySmall),
          if (bid.message?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(bid.message!,
                style: const TextStyle(color: AppColors.textSecondary))
          ],
          if (onAccept != null) ...[
            const SizedBox(height: 14),
            PrimaryButton(
                label: isAccepting
                    ? strings.business('accepting')
                    : strings.business('accept_offer'),
                onPressed: isAccepting ? null : onAccept)
          ],
          if (bid.status == BidStatus.accepted) ...[
            const SizedBox(height: 12),
            Text(strings.business('contact_revealed'),
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600))
          ],
        ]),
      ),
    );
  }
}

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          PageHeader(
              title: strings.business('your_profile'),
              subtitle: strings.business('manage_profile')),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const CircleAvatar(radius: 28, child: Text('A')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(profile?.fullName ?? 'Alex Tan',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          Text(auth.user?.email ?? 'demo@ofrivo.local')
                        ])),
                    IconButton(
                        onPressed: () {}, icon: const Icon(Icons.edit_outlined))
                  ]))),
          const SizedBox(height: 16),
          ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(strings.business('become_provider')),
              subtitle: Text(strings.business('apply_receive_requests')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/provider/apply')),
          ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(strings.business('notification_centre')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/notifications')),
          ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings.business('sign_out')),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/onboarding');
              }),
        ]);
  }
}

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen(
      {required this.providerId, this.profile, super.key});

  final String providerId;
  final ProviderProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    final asyncProfile = profile == null
        ? ref.watch(customerProviderProfileProvider(providerId))
        : null;
    final provider = profile ?? asyncProfile?.value;
    if (provider == null) {
      if (asyncProfile?.isLoading ?? false) {
        return const Padding(
            padding: EdgeInsets.all(20), child: LoadingSkeleton());
      }
      return ErrorState(
          onRetry: () =>
              ref.invalidate(customerProviderProfileProvider(providerId)));
    }
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(strings.business('provider_profile'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          ProviderCard(provider: provider),
          const SizedBox(height: 18),
          Text(provider.bio, style: Theme.of(context).textTheme.bodyLarge),
          if (provider.portfolioUrls.isNotEmpty) ...[
            const SizedBox(height: 18),
            PortfolioGallery(urls: provider.portfolioUrls),
          ],
          const SizedBox(height: 18),
          Wrap(spacing: 8, children: [
            StatusBadge(label: provider.verification.name),
            if (provider.isAvailable)
              StatusBadge(label: strings.business('available'))
          ]),
          const SizedBox(height: 18),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.lock_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(strings.business('contact_after_accept')))
                  ])))
        ]);
  }
}
