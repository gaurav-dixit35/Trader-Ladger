import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../security/application/pin_lock_providers.dart';
import 'notification_providers.dart';

final notificationBootstrapProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final pinState = ref.watch(pinLockControllerProvider);
  final isLoggedIn = authState.asData?.value != null;
  if (!isLoggedIn || !pinState.isUnlocked) {
    return;
  }

  final scheduler = ref.read(reminderSchedulerProvider);
  unawaited(scheduler.refreshSchedules().catchError((_) => 0));

  final timer = Timer.periodic(const Duration(hours: 6), (_) {
    unawaited(scheduler.refreshSchedules().catchError((_) => 0));
  });
  ref.onDispose(timer.cancel);
});
