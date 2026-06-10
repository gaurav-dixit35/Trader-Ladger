class DatabaseValueConverters {
  const DatabaseValueConverters._();

  static int boolToInt(bool value) => value ? 1 : 0;

  static bool intToBool(int value) => value == 1;

  static int dateTimeToMillis(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch;
  }

  static DateTime millisToDateTime(int value) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }

  static int? nullableDateTimeToMillis(DateTime? value) {
    return value == null ? null : dateTimeToMillis(value);
  }

  static DateTime? nullableMillisToDateTime(int? value) {
    return value == null ? null : millisToDateTime(value);
  }
}
