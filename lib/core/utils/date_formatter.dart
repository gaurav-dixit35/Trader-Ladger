import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayDate = DateFormat('dd MMM yyyy');
  static final DateFormat _weekday = DateFormat('EEEE');
  static final DateFormat _month = DateFormat('MMMM yyyy');

  static String displayDate(DateTime value) => _displayDate.format(value);

  static String weekday(DateTime value) => _weekday.format(value);

  static String month(DateTime value) => _month.format(value);
}
