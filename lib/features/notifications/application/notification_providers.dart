import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_providers.dart';
import '../data/local_notification_service.dart';
import '../data/reminder_dao.dart';
import '../data/reminder_scheduler.dart';

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final reminderDaoProvider = Provider<ReminderDao>((ref) {
  return ReminderDao(ref.watch(localDatabaseProvider));
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    reminderDao: ref.watch(reminderDaoProvider),
    notificationService: ref.watch(localNotificationServiceProvider),
  );
});

final refreshRemindersProvider = FutureProvider<int>((ref) {
  return ref.watch(reminderSchedulerProvider).refreshSchedules();
});
