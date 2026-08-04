import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Notification centre', body: ListView(padding: const EdgeInsets.all(20), children: [Card(child: ListTile(leading: const Icon(Icons.local_offer_outlined), title: const Text('New offer received'), subtitle: const Text('Your toilet blockage job has a new offer.'))), const SizedBox(height: 10), Card(child: ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('Provider verification pending'), subtitle: const Text('Your application is waiting for review.')))]));
}

class SuspendedAccountScreen extends StatelessWidget {
  const SuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Account suspended', body: const EmptyState(title: 'Account access is paused', message: 'Contact support if you believe this was a mistake.', icon: Icons.lock_outline));
}

class ProviderModeGuardScreen extends StatelessWidget {
  const ProviderModeGuardScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified_user_outlined, size: 44), const SizedBox(height: 14), Text('Provider approval required', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Complete verification before viewing jobs or submitting bids.', textAlign: TextAlign.center), const SizedBox(height: 18), PrimaryButton(label: 'Start provider application', onPressed: () => context.go('/provider/apply'))]))));
}
