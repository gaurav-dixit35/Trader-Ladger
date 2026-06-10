enum ReminderType {
  chequeDeposit,
  pendingPayment,
}

class ReminderItem {
  const ReminderItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final int id;
  final ReminderType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
}
