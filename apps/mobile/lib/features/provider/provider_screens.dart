import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../shell/shell_screen.dart';

class BecomeProviderScreen extends StatelessWidget {
  const BecomeProviderScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Become a provider', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Apply once and, after approval, switch between customer and provider modes.'), const SizedBox(height: 22), const TextField(decoration: InputDecoration(labelText: 'Business or display name')), const SizedBox(height: 14), const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'Tell customers about your work')), const SizedBox(height: 16), const Text('Services', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(label: 'Plumbing'), CategoryChip(label: 'Handyman'), CategoryChip(label: 'Electrical')]), const SizedBox(height: 16), const Text('Service areas', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Wrap(spacing: 8, children: [AreaChip(label: 'Johor Bahru'), AreaChip(label: 'Mount Austin')]), const SizedBox(height: 20), PrimaryButton(label: 'Continue application', onPressed: () => context.go('/provider/verification'))]);
}

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [Text('Verification status', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.hourglass_top_rounded, size: 34, color: AppColors.warning), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pending review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), SizedBox(height: 4), Text('The fake-data application is waiting for an admin decision.')]))])), const SizedBox(height: 18), const PhotoUploader(count: 2), const SizedBox(height: 18), SecondaryButton(label: 'View application details', onPressed: () {}), const SizedBox(height: 12), const Text('Approved providers will be able to access Job Feed and submit bids.', style: TextStyle(color: AppColors.textSecondary))]);
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
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [const PageHeader(title: 'Provider profile', subtitle: 'Your public profile and availability.'), ProviderCard(provider: provider), const SizedBox(height: 16), SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Available for new jobs'), subtitle: const Text('Show matching requests in your feed')), ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('Verification status'), subtitle: const Text('Approved'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/provider/verification'))]);
  }
}

