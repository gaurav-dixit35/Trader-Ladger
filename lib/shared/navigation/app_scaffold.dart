import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  static const _destinations = [
    _NavigationItem(
      route: AppRoute.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Home',
    ),
    _NavigationItem(
      route: AppRoute.traders,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Traders',
    ),
    _NavigationItem(
      route: AppRoute.entries,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Entries',
    ),
    _NavigationItem(
      route: AppRoute.reports,
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
      label: 'Reports',
    ),
    _NavigationItem(
      route: AppRoute.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) {
            return;
          }
          context.go(_destinations[index].route.path);
        },
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoute.recycleBin.path)) {
      return _destinations.indexWhere(
        (item) => item.route == AppRoute.settings,
      );
    }

    final index = _destinations.indexWhere((item) {
      if (item.route.path == AppRoute.dashboard.path) {
        return location == item.route.path;
      }
      return location.startsWith(item.route.path);
    });

    return index == -1 ? 0 : index;
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final AppRoute route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
