import 'package:intl/intl.dart';
import 'app_time.dart';

class DateHelper {


  static String nowFull() {
    return formatDate(AppTime.now());
  }

  static String formatTime(DateTime date) {
   return DateFormat('HH:mm', 'en_US').format(date);
  }

  static String nowTime() {
    return formatTime(AppTime.now());
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'en_US').format(date);
  }

  static String nowDate() {
    return formatDate(AppTime.now());
  }


  static String nowDayDate() {
    return formatDate(AppTime.now());
  }
  static String formatDateTimeShort(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm', 'en_US').format(date);
  }

  static String formatDay(DateTime date) {
    return DateFormat('EEEE', 'en_US').format(date);
  }

  static String formatNumericCompact(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatToIndonesian(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  static String nowDay() {
    return formatDay(AppTime.now());
  }

  // AppTime.now() = jam dinding WIB dengan flag UTC, sedangkan tanggal dari server/picker
  // biasanya lokal — bandingkan field jam dindingnya saja supaya selisihnya benar.
  static DateTime _wallClock(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);

  /// "Baru saja", "5 menit lalu", "3 jam lalu", "Kemarin", "4 hari lalu".
  static String timeAgo(DateTime date) {
    final diff = _wallClock(AppTime.now()).difference(_wallClock(date));
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 2) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  /// "Hari ini, 09:45", "Besok, 08:00", "Kemarin, 17:10", atau "Kam, 15 Okt, 10:00".
  static String relativeDayTime(DateTime date) {
    final now = _wallClock(AppTime.now());
    final t = _wallClock(date);
    final dayDiff = DateTime.utc(t.year, t.month, t.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    final day = switch (dayDiff) {
      0 => 'Hari ini',
      1 => 'Besok',
      -1 => 'Kemarin',
      _ => DateFormat('EEE, d MMM', 'id_ID').format(t),
    };
    return '$day, ${DateFormat('HH:mm').format(t)}';
  }

  static ({DateTime start, DateTime end, String label})? resolveRangePreset(String? preset) {
    if (preset == null || preset.isEmpty) return null;
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case 'today':
        return (start: today, end: today, label: 'Today');
      case 'this_week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (start: startOfWeek, end: today, label: 'This Week');
      case 'last_week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
        final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
        return (start: startOfLastWeek, end: endOfLastWeek, label: 'Last Week');
      case 'this_month':
        final startOfMonth = DateTime(today.year, today.month, 1);
        return (start: startOfMonth, end: today, label: 'This Month');
      case 'last_month':
        final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
        final endOfLastMonth = DateTime(today.year, today.month, 0);
        return (start: startOfLastMonth, end: endOfLastMonth, label: 'Last Month');
      case 'last_1_year':
        return (start: DateTime(today.year - 1, today.month, today.day), end: today, label: 'Last 1 Year');
      default:
        return null;
    }
  }

  String formatInboxDate(String? value) {
  if (value == null || value.isEmpty) return '-';

  final date = DateTime.tryParse(value);

  if (date == null) return value;

  final now = AppTime.now();

  final isToday =
      date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;

  if (isToday) {
    return DateFormat('HH:mm').format(date);
  }

  return DateFormat('dd MMM yyyy').format(date);
}
}
