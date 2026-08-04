import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.title, required this.body, super.key, this.actions});

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.label, required this.onPressed, super.key, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)]);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(onPressed: onPressed, child: child),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.label, required this.onPressed, super.key, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(foregroundColor: AppColors.danger),
        child: Text(label),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, super.key});

  final String label;

  Color get _color {
    final value = label.toLowerCase();
    if (value.contains('open') || value.contains('approved') || value.contains('verified') || value.contains('completed')) return AppColors.success;
    if (value.contains('pending') || value.contains('urgent')) return AppColors.warning;
    if (value.contains('cancel') || value.contains('reject') || value.contains('suspend') || value.contains('expired')) return AppColors.danger;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _color.withOpacity(0.10), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) => const StatusBadge(label: 'Verified');
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(avatar: const Icon(Icons.category_outlined, size: 16), label: Text(label));
}

class AreaChip extends StatelessWidget {
  const AreaChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(avatar: const Icon(Icons.location_on_outlined, size: 16), label: Text(label));
}

class JobCard extends StatelessWidget {
  const JobCard({required this.job, super.key, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(job.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              if (job.urgent) const StatusBadge(label: 'Urgent'),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(label: job.category), AreaChip(label: job.area)]),
            const SizedBox(height: 12),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(children: [
              Text('RM${job.budget.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(job.time, style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 10),
            Row(children: [StatusBadge(label: job.status.name), const Spacer(), Text('${job.bidCount} offers received', style: Theme.of(context).textTheme.bodySmall)]),
          ]),
        ),
      ),
    );
  }
}

class BidCard extends StatelessWidget {
  const BidCard({required this.bid, super.key, this.onTap});

  final Bid bid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(bid.providerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              if (bid.verified) const VerifiedBadge(),
            ]),
            const SizedBox(height: 8),
            Text('${bid.rating.toStringAsFixed(1)} ★  ·  ${bid.completedJobs} jobs completed'),
            const SizedBox(height: 12),
            Row(children: [Text('RM${bid.amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)), const Spacer(), StatusBadge(label: bid.status.name)]),
            const SizedBox(height: 10),
            Text('Available ${bid.availableAt}'),
            const SizedBox(height: 8),
            Text('Includes: ${bid.inclusions}'),
            Text('Excludes: ${bid.exclusions}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({required this.provider, super.key, this.onTap});

  final ProviderProfile provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(radius: 26, backgroundColor: const Color(0xFFD4ECEC), child: Text(provider.name.substring(0, 1))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(provider.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), Text(provider.category), Text('${provider.rating.toStringAsFixed(1)} ★  ·  ${provider.completedJobs} completed')]))),
      const Icon(Icons.chevron_right),
    ]))));
  }
}

class BudgetInput extends StatelessWidget {
  const BudgetInput({super.key, this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Budget', prefixText: 'RM '));
}

class DateTimeSelector extends StatelessWidget {
  const DateTimeSelector({super.key, this.value = 'Choose a date and time'});

  final String value;

  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule_outlined), title: const Text('Service time'), subtitle: Text(value), trailing: const Icon(Icons.chevron_right));
}

class PhotoUploader extends StatelessWidget {
  const PhotoUploader({super.key, this.count = 0});

  final int count;

  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outline)), child: Column(children: [const Icon(Icons.add_a_photo_outlined, size: 30), const SizedBox(height: 8), Text('$count/5 photos selected'), const SizedBox(height: 8), const Text('Photo upload placeholder', style: TextStyle(color: AppColors.textSecondary))]));
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, super.key, this.icon = Icons.inbox_outlined});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: AppColors.textSecondary), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary))])));
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(title: 'Something went wrong', message: 'Please check your connection and try again.', icon: Icons.error_outline);
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Card(child: Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFE7EEF0), borderRadius: BorderRadius.circular(16))));
}

class ConfirmationDialog {
  static Future<bool> show(BuildContext context, {required String title, required String message}) async {
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))]));
    return result ?? false;
  }
}

class FilterBottomSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Filter jobs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 16), const Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(label: 'Plumbing'), CategoryChip(label: 'Electrical'), AreaChip(label: 'Mount Austin'), AreaChip(label: 'Taman Molek')]), const SizedBox(height: 20), PrimaryButton(label: 'Apply filters', onPressed: () => Navigator.pop(context))])));
  }
}
