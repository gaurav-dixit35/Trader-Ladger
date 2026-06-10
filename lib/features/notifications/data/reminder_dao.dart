import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../domain/reminder_item.dart';

class ReminderDao extends BaseDao {
  const ReminderDao(super.localDatabase);

  Future<List<ReminderItem>> loadUpcomingReminders() async {
    final reminders = <ReminderItem>[];
    reminders.addAll(await _loadChequeDepositReminders());
    reminders.addAll(await _loadPendingPaymentReminders());
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  Future<List<ReminderItem>> _loadChequeDepositReminders() async {
    final db = await database;
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    final rows = await db.rawQuery(
      '''
      SELECT
        e.id,
        e.bill_number,
        e.cheque_amount,
        e.deposit_date,
        t.name AS trader_name
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
        AND e.cheque_amount > 0
        AND e.deposit_date IS NOT NULL
        AND e.deposit_date >= ?
        AND e.deposit_date <= ?
      ORDER BY e.deposit_date ASC
      ''',
      [
        DatabaseValueConverters.dateTimeToMillis(now),
        DatabaseValueConverters.dateTimeToMillis(end),
      ],
    );

    return rows.map((row) {
      final depositDate = DatabaseValueConverters.millisToDateTime(
        row['deposit_date']! as int,
      );
      return ReminderItem(
        id: _stableNotificationId(row['id']! as String, 1),
        type: ReminderType.chequeDeposit,
        title: 'Cheque deposit reminder',
        body:
            '${row['trader_name']} bill ${row['bill_number']} cheque amount is due.',
        scheduledAt: _atBusinessHour(depositDate),
      );
    }).toList(growable: false);
  }

  Future<List<ReminderItem>> _loadPendingPaymentReminders() async {
    final db = await database;
    final now = DateTime.now();
    final rows = await db.rawQuery('''
      SELECT
        e.id,
        e.bill_number,
        e.pending_amount,
        e.entry_date,
        t.name AS trader_name
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
        AND e.pending_amount > 0
      ORDER BY e.entry_date ASC
      LIMIT 50
    ''');

    return rows.map((row) {
      final entryDate = DatabaseValueConverters.millisToDateTime(
        row['entry_date']! as int,
      );
      final reminderDate = entryDate.add(const Duration(days: 3));
      final scheduledAt = reminderDate.isBefore(now)
          ? now.add(const Duration(minutes: 10))
          : reminderDate;

      return ReminderItem(
        id: _stableNotificationId(row['id']! as String, 2),
        type: ReminderType.pendingPayment,
        title: 'Pending payment reminder',
        body:
            '${row['trader_name']} bill ${row['bill_number']} has pending payment.',
        scheduledAt: _atBusinessHour(scheduledAt),
      );
    }).toList(growable: false);
  }

  DateTime _atBusinessHour(DateTime value) {
    final scheduledAt = DateTime(value.year, value.month, value.day, 9);
    final now = DateTime.now();
    if (scheduledAt.isBefore(now)) {
      return now.add(const Duration(minutes: 10));
    }

    return scheduledAt;
  }

  int _stableNotificationId(String id, int suffix) {
    final hash = id.codeUnits.fold<int>(0, (value, unit) {
      return (value * 31 + unit) & 0x3fffffff;
    });
    return hash + suffix;
  }
}
