import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'job_lifecycle_controller.dart';
import 'job_lifecycle_models.dart';

class JobLifecycleActions extends ConsumerWidget {
  const JobLifecycleActions(
      {required this.jobId,
      required this.status,
      required this.role,
      this.includeCancel = false,
      super.key});

  final String jobId;
  final JobStatus status;
  final AppMode role;
  final bool includeCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobLifecycleControllerProvider(jobId));
    final controller = ref.read(jobLifecycleControllerProvider(jobId).notifier);
    final buttons = <Widget>[];
    if (role == AppMode.provider && status == JobStatus.assigned) {
      buttons.add(PrimaryButton(
          label: state.isSubmitting ? 'Starting...' : 'Mark as started',
          onPressed: state.isSubmitting
              ? null
              : () => _run(
                  context, () => controller.start(jobId), 'Job started.')));
    }
    if (status == JobStatus.inProgress) {
      buttons.add(PrimaryButton(
          label: state.isSubmitting ? 'Completing...' : 'Mark as completed',
          onPressed: state.isSubmitting
              ? null
              : () => _run(context, () => controller.complete(jobId),
                  'Job completed.')));
    }
    if (includeCancel &&
        (status == JobStatus.assigned || status == JobStatus.inProgress)) {
      buttons.add(DangerButton(
          label: state.isSubmitting ? 'Cancelling...' : 'Cancel assigned job',
          onPressed: state.isSubmitting
              ? null
              : () => _confirmCancel(context, controller)));
    }
    if (status == JobStatus.assigned || status == JobStatus.inProgress) {
      buttons.add(OutlinedButton.icon(
          onPressed: state.isSubmitting
              ? null
              : () => _confirmNoShow(context, controller),
          icon: const Icon(Icons.person_off_outlined),
          label: Text(role == AppMode.customer
              ? 'Mark provider no-show'
              : 'Report customer no-show')));
    }
    if (status == JobStatus.completed) {
      buttons.add(Row(children: [
        Expanded(
            child: OutlinedButton.icon(
                onPressed: () => context.go(_reviewPath()),
                icon: const Icon(Icons.star_outline),
                label: const Text('Leave a review'))),
        const SizedBox(width: 10),
        Expanded(
            child: OutlinedButton.icon(
                onPressed: () => context.go(_reportPath()),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report')))
      ]));
    }
    if (state.info != null) {
      buttons.add(Card(
        color: const Color(0xFFEAF5F3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(child: Text(state.info!)),
          ]),
        ),
      ));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      for (final button in buttons)
        Padding(padding: const EdgeInsets.only(top: 10), child: button)
    ]);
  }

  Future<void> _run(BuildContext context, Future<bool> Function() action,
      String message) async {
    final success = await action();
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmCancel(
      BuildContext context, JobLifecycleController controller) async {
    final confirmed = await ConfirmationDialog.show(context,
        title: 'Cancel this assigned job?',
        message: 'The customer will be notified and the job will stop here.');
    if (!confirmed || !context.mounted) return;
    await _run(
        context,
        () => controller.cancel(jobId, reason: 'Cancelled by provider.'),
        'Job cancelled.');
  }

  Future<void> _confirmNoShow(
      BuildContext context, JobLifecycleController controller) async {
    final confirmed = await ConfirmationDialog.show(context,
        title: 'Mark a no-show?',
        message:
            'This creates a private safety event for the job and notifies the other participant.');
    if (!confirmed || !context.mounted) return;
    await _run(
        context,
        () => controller.markNoShow(jobId,
            reason: role == AppMode.customer
                ? 'Customer marked the provider as a no-show.'
                : 'Provider marked the customer as a no-show.'),
        'No-show marked for safety review.');
  }

  String _reviewPath() => role == AppMode.provider
      ? '/provider/assigned/$jobId/review'
      : '/customer/jobs/$jobId/review';

  String _reportPath() => role == AppMode.provider
      ? '/provider/assigned/$jobId/report'
      : '/customer/jobs/$jobId/report';
}

class JobEventTimeline extends ConsumerWidget {
  const JobEventTimeline({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobLifecycleControllerProvider(jobId));
    if (!state.initialized && state.isLoading) return const LoadingSkeleton();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Job history',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (state.events.isEmpty)
            const Text('No activity recorded yet.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (final event in state.events.take(8))
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_eventLabel(event.eventType),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(_formatDate(event.createdAt),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12))
                            ]))
                      ])),
        ]),
      ),
    );
  }

  static String _eventLabel(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  var rating = 5;
  final commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final state = ref.watch(jobLifecycleControllerProvider(widget.jobId));
    final title = mode == AppMode.provider
        ? 'Review the customer'
        : 'Review the provider';
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Your review helps the Ofrivo community choose reliable people.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 22),
          Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var index = 1; index <= 5; index++)
              IconButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => setState(() => rating = index),
                  icon: Icon(index <= rating ? Icons.star : Icons.star_border,
                      color: AppColors.warning, size: 34))
          ])),
          const SizedBox(height: 12),
          TextField(
              controller: commentController,
              enabled: !state.isSubmitting,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'What went well?')),
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Text(state.error!, style: const TextStyle(color: AppColors.danger))
          ],
          const SizedBox(height: 18),
          PrimaryButton(
              label: state.isSubmitting ? 'Submitting...' : 'Submit review',
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final ok = await ref
                          .read(jobLifecycleControllerProvider(widget.jobId)
                              .notifier)
                          .submitReview(
                              widget.jobId,
                              ReviewDraft(
                                  rating: rating,
                                  comment: commentController.text));
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Review submitted.')));
                        context.pop();
                      }
                    })
        ]);
  }
}

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String reason = reportReasonOptions.first;
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobLifecycleControllerProvider(widget.jobId));
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Report an issue',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Reports are private and reviewed by the Ofrivo safety team.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
              initialValue: reason,
              items: [
                for (final option in reportReasonOptions)
                  DropdownMenuItem(value: option, child: Text(option))
              ],
              onChanged: state.isSubmitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => reason = value);
                    },
              decoration: const InputDecoration(labelText: 'Reason')),
          const SizedBox(height: 14),
          TextField(
              controller: descriptionController,
              enabled: !state.isSubmitting,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                  labelText: 'What happened?',
                  hintText:
                      'Include dates, messages, or other useful details.')),
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Text(state.error!, style: const TextStyle(color: AppColors.danger))
          ],
          const SizedBox(height: 18),
          PrimaryButton(
              label: state.isSubmitting ? 'Submitting...' : 'Submit report',
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final ok = await ref
                          .read(jobLifecycleControllerProvider(widget.jobId)
                              .notifier)
                          .submitReport(
                              widget.jobId,
                              ReportDraft(
                                  reasonCode: reason,
                                  description: descriptionController.text));
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Report submitted to the safety team.')));
                        context.pop();
                      }
                    })
        ]);
  }
}
