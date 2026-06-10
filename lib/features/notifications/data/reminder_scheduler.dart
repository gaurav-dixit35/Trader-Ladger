import 'local_notification_service.dart';
import 'reminder_dao.dart';

class ReminderScheduler {
  const ReminderScheduler({
    required this.reminderDao,
    required this.notificationService,
  });

  final ReminderDao reminderDao;
  final LocalNotificationService notificationService;

  Future<int> refreshSchedules() async {
    final reminders = await reminderDao.loadUpcomingReminders();
    await notificationService.replaceScheduledReminders(reminders);
    return reminders.length;
  }
}
