import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/application/notification_bootstrap_provider.dart';
import 'features/sync/application/cloud_sync_providers.dart';

class TraderLedgerApp extends ConsumerStatefulWidget {
  const TraderLedgerApp({super.key});

  @override
  ConsumerState<TraderLedgerApp> createState() => _TraderLedgerAppState();
}

class _TraderLedgerAppState extends ConsumerState<TraderLedgerApp> {
  @override
  Widget build(BuildContext context) {
    ref.watch(cloudSyncBootstrapProvider);
    ref.watch(notificationBootstrapProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
