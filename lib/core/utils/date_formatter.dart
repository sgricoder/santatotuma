import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final _date = DateFormat('dd/MM/yyyy', 'es_CO');
  static final _time = DateFormat('HH:mm', 'es_CO');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es_CO');
  static final _dayMonth = DateFormat('d MMM', 'es_CO');

  static String formatDate(DateTime d) => _date.format(d);
  static String formatTime(DateTime d) => _time.format(d);
  static String formatDateTime(DateTime d) => _dateTime.format(d);
  static String formatDayMonth(DateTime d) => _dayMonth.format(d);

  /// "hace 5 min", "hace 1 h", "hace 2 d"
  static String timeAgo(DateTime from) {
    final diff = DateTime.now().difference(from);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  /// Minutos transcurridos desde `from` (para color en cocina)
  static int minutesElapsed(DateTime from) =>
      DateTime.now().difference(from).inMinutes;
}
