import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isProvider = mode == AppMode.provider;
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
          IconButton(onPressed: () => context.go('/notifications'), icon: const Icon(Icons.notifications_none), tooltip: 'Notifications'),
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

