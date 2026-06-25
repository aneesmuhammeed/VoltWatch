import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _dateTimeFormat = DateFormat('MMM dd, HH:mm');
  static final _fullFormat = DateFormat('MMM dd, yyyy – HH:mm');

  static String time(DateTime dt) => _timeFormat.format(dt);
  static String date(DateTime dt) => _dateFormat.format(dt);
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String full(DateTime dt) => _fullFormat.format(dt);

  /// "2 min ago", "1 hr ago", "Yesterday", etc.
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return date(dt);
  }
}
