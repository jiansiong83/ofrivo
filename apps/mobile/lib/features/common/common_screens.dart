import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../notifications/notification_controller.dart';
import '../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    return AppScaffold(
      title: state.unreadCount == 0
          ? 'Notification centre'
          : 'Notification centre (${state.unreadCount})',
      actions: [
        if (state.unreadCount > 0)
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(notificationControllerProvider.notifier)
                    .markAllRead(),
            child: const Text('Mark all read'),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!state.initialized && state.isLoading)
            const LoadingSkeleton()
          else if (state.error != null && state.notifications.isEmpty)
            ErrorState(
                onRetry: () =>
                    ref.read(notificationControllerProvider.notifier).load())
          else if (state.notifications.isEmpty)
            const EmptyState(
                title: 'All caught up',
                message: 'New offers and job updates will appear here.',
                icon: Icons.notifications_none)
          else
            for (final notification in state.notifications)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: notification.isRead ? null : const Color(0xFFEAF5F3),
                  child: ListTile(
                    leading: Icon(_iconFor(notification.type),
                        color: notification.isRead ? null : AppColors.primary),
                    title: Row(children: [
                      Expanded(
                          child: Text(notification.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      if (!notification.isRead) const StatusBadge(label: 'New')
                    ]),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(notification.body)),
                    onTap: () async {
                      await ref
                          .read(notificationControllerProvider.notifier)
                          .markRead(notification.id);
                      final referenceId = notification.referenceId;
                      if (!context.mounted || referenceId == null) return;
                      final mode = ref.read(appModeProvider);
                      if (notification.referenceType == 'job') {
                        if (mode == AppMode.provider &&
                            notification.type == NotificationType.newJob) {
                          context.go('/provider/jobs/$referenceId');
                        } else {
                          context.go(mode == AppMode.provider
                              ? '/provider/assigned/$referenceId'
                              : '/customer/jobs/$referenceId');
                        }
                      }
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newJob:
        return Icons.rss_feed_outlined;
      case NotificationType.newBid:
      case NotificationType.bidAccepted:
        return Icons.local_offer_outlined;
      case NotificationType.jobAssigned:
        return Icons.assignment_turned_in_outlined;
      case NotificationType.jobExpiring:
        return Icons.schedule_outlined;
      case NotificationType.jobExpired:
        return Icons.timer_off_outlined;
      case NotificationType.providerApproved:
        return Icons.verified_outlined;
      case NotificationType.providerRejected:
      case NotificationType.providerSuspended:
        return Icons.gpp_bad_outlined;
      case NotificationType.jobStarted:
        return Icons.play_circle_outline;
      case NotificationType.jobCompleted:
        return Icons.task_alt_outlined;
      case NotificationType.jobCancelled:
        return Icons.cancel_outlined;
      case NotificationType.noShow:
        return Icons.person_off_outlined;
      case NotificationType.generic:
        return Icons.notifications_none;
    }
  }
}

class SuspendedAccountScreen extends StatelessWidget {
  const SuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppScaffold(
      title: 'Account suspended',
      body: EmptyState(
          title: 'Account access is paused',
          message: 'Contact support if you believe this was a mistake.',
          icon: Icons.lock_outline));
}

class ProviderModeGuardScreen extends StatelessWidget {
  const ProviderModeGuardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 44),
                const SizedBox(height: 14),
                Text(
                  'Provider approval required',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete verification before viewing jobs or submitting bids.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Start provider application',
                  onPressed: () => context.go('/provider/apply'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
