import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/entries/presentation/screens/entry_detail_screen.dart';
import '../features/entries/presentation/screens/entries_screen.dart';
import '../features/recycle_bin/presentation/screens/recycle_bin_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/security/application/pin_lock_providers.dart';
import '../features/security/presentation/screens/pin_lock_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/traders/presentation/screens/trader_profile_screen.dart';
import '../features/traders/presentation/screens/traders_screen.dart';
import '../shared/navigation/app_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final pinState = ref.watch(pinLockControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoute.splash.path;
      final isLoggingIn = state.matchedLocation == AppRoute.login.path;
      final isPinLock = state.matchedLocation == AppRoute.pinLock.path;
      final isLoading = authState.isLoading || pinState.isChecking;
      final isLoggedIn = authState.asData?.value != null;

      if (isLoading) {
        return null;
      }

      if (isSplash) {
        return null;
      }

      if (!isLoggedIn) {
        return isLoggingIn ? null : AppRoute.login.path;
      }

      if (pinState.requiresPin) {
        return isPinLock ? null : AppRoute.pinLock.path;
      }

      if (isLoggingIn || isPinLock) {
        return AppRoute.traders.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.pinLock.path,
        name: AppRoute.pinLock.name,
        builder: (context, state) => const PinLockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoute.dashboard.path,
            name: AppRoute.dashboard.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoute.traders.path,
            name: AppRoute.traders.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const TradersScreen()),
            routes: [
              GoRoute(
                path: ':traderId',
                name: AppRoute.traderProfile.name,
                pageBuilder: (context, state) {
                  final traderId = state.pathParameters['traderId']!;
                  return _fadePage(
                    state,
                    TraderProfileScreen(traderId: traderId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.entries.path,
            name: AppRoute.entries.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const EntriesScreen()),
            routes: [
              GoRoute(
                path: ':entryId',
                name: AppRoute.entryDetail.name,
                pageBuilder: (context, state) {
                  final entryId = state.pathParameters['entryId']!;
                  return _fadePage(
                    state,
                    EntryDetailScreen(entryId: entryId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.reports.path,
            name: AppRoute.reports.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const ReportsScreen()),
          ),
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsScreen()),
          ),
          GoRoute(
            path: AppRoute.recycleBin.path,
            name: AppRoute.recycleBin.name,
            pageBuilder: (context, state) =>
                _fadePage(state, const RecycleBinScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

enum AppRoute {
  splash('/splash'),
  login('/login'),
  pinLock('/pin-lock'),
  dashboard('/'),
  traders('/traders'),
  traderProfile(':traderId'),
  entries('/entries'),
  entryDetail(':entryId'),
  reports('/reports'),
  settings('/settings'),
  recycleBin('/recycle-bin');

  const AppRoute(this.path);

  final String path;
}
