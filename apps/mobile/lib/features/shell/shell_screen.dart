import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_screens.dart';
import '../common/common_screens.dart';
import '../notifications/notification_controller.dart';
import '../notifications/push_registration_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user == null && next.user != null && !next.isSuspended) {
        ref.read(pushRegistrationControllerProvider.notifier).register();
      }
      if (previous?.user != null && next.user == null) {
        ref.read(pushRegistrationControllerProvider.notifier).unregister();
      }
    });
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.isSuspended) return const SuspendedAccountScreen();
    final notificationState = ref.watch(notificationControllerProvider);
    ref.watch(pushRegistrationControllerProvider);
    final mode = ref.watch(appModeProvider);
    final isProvider = mode == AppMode.provider;
    if (isProvider && !auth.isApprovedProvider) return const Scaffold(body: ProviderModeGuardScreen());
    final tabs = isProvider
        ? const [
            _NavItem('Job Feed', Icons.rss_feed_outlined, '/provider/feed'),
            _NavItem('My Bids', Icons.request_quote_outlined, '/provider/bids'),
            _NavItem('Assigned', Icons.assignment_outlined, '/provider/assigned'),
            _NavItem('Profile', Icons.person_outline, '/provider/profile'),
          ]
        : const [
            _NavItem('Home', Icons.home_outlined, '/customer/home'),
            _NavItem('Post Job', Icons.add_circle_outline, '/customer/post'),
            _NavItem('My Jobs', Icons.work_outline, '/customer/jobs'),
            _NavItem('Profile', Icons.person_outline, '/customer/profile'),
          ];
    final path = GoRouterState.of(context).uri.path;
    var selectedIndex = tabs.indexWhere((item) => path == item.path || path.startsWith(item.path));
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Provider mode' : 'Ofrivo'),
        actions: [
          IconButton(onPressed: () => context.go('/notifications'), icon: _NotificationIcon(unreadCount: notificationState.unreadCount), tooltip: 'Notifications'),
          PopupMenuButton<String>(
            tooltip: 'Switch mode',
            onSelected: (value) {
              if (value == 'provider') {
                ref.read(appModeProvider.notifier).state = AppMode.provider;
                context.go('/provider/feed');
              } else {
                ref.read(appModeProvider.notifier).state = AppMode.customer;
                context.go('/customer/home');
              }
            },
            itemBuilder: (context) => [
              if (mode == AppMode.customer) const PopupMenuItem(value: 'provider', child: Text('Switch to Provider Mode')),
              if (mode == AppMode.provider) const PopupMenuItem(value: 'customer', child: Text('Switch to Customer Mode')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(tabs[index].path),
        destinations: [for (final item in tabs) NavigationDestination(icon: Icon(item.icon), label: item.label)],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final label = unreadCount == 0
        ? 'Notifications'
        : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}';
    return Semantics(
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (unreadCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

class PageHeader extends StatelessWidget {
  const PageHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)), const SizedBox(height: 6), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))]));
}
