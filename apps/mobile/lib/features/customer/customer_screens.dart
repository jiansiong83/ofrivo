import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../../shared/widgets/app_widgets.dart';
import '../shell/shell_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(fakeJobsProvider);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      const PageHeader(title: 'Good morning, Alex', subtitle: 'What would you like to get done today?'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PrimaryButton(label: 'Post a new job', icon: Icons.add, onPressed: () => context.go('/customer/post'))),
      const SizedBox(height: 22),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Your active jobs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
      const SizedBox(height: 12),
      for (final job in jobs.take(2)) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: JobCard(job: job, onTap: () => context.go('/customer/jobs/${job.id}'))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.shield_outlined, color: AppColors.primary), const SizedBox(width: 12), const Expanded(child: Text('Compare verified local providers and keep your address private until you choose.'))])))),
    ]);
  }
}

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final titleController = TextEditingController();
  final budgetController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
        Text('Post a job', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Tell providers what you need. This is a fake-data preview.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 22),
        const Text('Service category', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(label: 'Plumbing'), CategoryChip(label: 'Electrical'), CategoryChip(label: 'Cleaning')]),
        const SizedBox(height: 18),
        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Job title', hintText: 'e.g. Fix leaking tap')),
        const SizedBox(height: 14),
        const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'Describe the problem')),
        const SizedBox(height: 14),
        const TextField(decoration: InputDecoration(labelText: 'Area', prefixIcon: Icon(Icons.location_on_outlined), hintText: 'e.g. Mount Austin')),
        const SizedBox(height: 14),
        BudgetInput(controller: budgetController),
        const SizedBox(height: 8),
        const DateTimeSelector(value: 'Today, 2pm–6pm'),
        const SizedBox(height: 8),
        const PhotoUploader(count: 0),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Preview job', onPressed: () => context.push('/customer/post/preview')),
      ]);
}

class PostJobPreviewScreen extends StatelessWidget {
  const PostJobPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [Text('Preview your job', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 16), const JobCard(job: _previewJob), const SizedBox(height: 18), PrimaryButton(label: 'Publish job', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake-data flow: job published.'))); context.go('/customer/jobs'); }), const SizedBox(height: 10), SecondaryButton(label: 'Keep editing', onPressed: () => context.pop())]);
}

const _previewJob = _PreviewJob();

class _PreviewJob extends Job {
  const _PreviewJob()
      : super(id: 'preview', title: 'Fix leaking tap', category: 'Plumbing / Toilet', area: 'Mount Austin', budget: 100, time: 'Today, 2pm–6pm', status: JobStatus.draft, bidCount: 0, description: 'Water is leaking from the kitchen tap.');
}

class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(fakeJobsProvider);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [const PageHeader(title: 'My jobs', subtitle: 'Track your requests from draft to completed.'), for (final job in jobs) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: JobCard(job: job, onTap: () => context.go('/customer/jobs/${job.id}')))]);
  }
}

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(fakeJobsProvider);
    final job = jobs.firstWhere((item) => item.id == jobId, orElse: () => jobs.first);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text(job.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10), Wrap(spacing: 8, children: [StatusBadge(label: job.status.name), AreaChip(label: job.area)]), const SizedBox(height: 18), Text(job.description, style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Budget', style: TextStyle(color: AppColors.textSecondary)), Text('RM${job.budget.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)), const SizedBox(height: 12), Text(job.time)]))), const SizedBox(height: 18), PrimaryButton(label: '${job.bidCount} offers received', onPressed: () => context.go('/customer/jobs/${job.id}/bids')), const SizedBox(height: 10), DangerButton(label: 'Cancel job', onPressed: () async { final confirmed = await ConfirmationDialog.show(context, title: 'Cancel this job?', message: 'This fake-data action will not change a backend record.'); if (confirmed && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation placeholder.'))); })]);
  }
}

class ReceivedBidsScreen extends ConsumerWidget {
  const ReceivedBidsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bids = ref.watch(fakeBidsProvider).where((bid) => bid.jobId == jobId).toList();
    if (bids.isEmpty) return const EmptyState(title: 'No bids yet', message: 'Approved providers will appear here when they respond.');
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Received bids', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('${bids.length} providers responded', style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 18), for (final bid in bids) Padding(padding: const EdgeInsets.only(bottom: 12), child: BidCard(bid: bid, onTap: () => context.go('/customer/providers/${bid.id}')))]);
  }
}

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
      const PageHeader(title: 'Your profile', subtitle: 'Manage your shared account details.'),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const CircleAvatar(radius: 28, child: Text('A')), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile?.fullName ?? 'Alex Tan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), Text(auth.user?.email ?? 'demo@ofrivo.local')])), IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined))]))),
      const SizedBox(height: 16),
      ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Become a provider'), subtitle: const Text('Apply to receive local job requests'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/provider/apply')),
      ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notification centre'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/notifications')),
      ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: () async { await ref.read(authControllerProvider.notifier).signOut(); if (context.mounted) context.go('/onboarding'); }),
    ]);
  }
}

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(providerProfileProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Provider profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), ProviderCard(provider: provider), const SizedBox(height: 18), Text(provider.bio, style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: 18), const Text('Contact details are revealed only after a bid is accepted.', style: TextStyle(color: AppColors.textSecondary))]);
  }
}
