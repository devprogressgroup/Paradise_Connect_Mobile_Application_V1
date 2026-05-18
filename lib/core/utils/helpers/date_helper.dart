import 'package:intl/intl.dart';

class DateHelper {


  static String nowFull() {
    return formatDate(DateTime.now());
  }

  /// 🔥 JAM SAJA (08:30 AM)
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'en_US').format(date);
  }

  static String nowTime() {
    return formatTime(DateTime.now());
  }

  /// 🔥 TANGGAL SAJA ( 13 April 2026)
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'en_US').format(date);
  }

  static String nowDate() {
    return formatDate(DateTime.now());
  }


  static String nowDayDate() {
    return formatDate(DateTime.now());
  }

/// 🔥 16 May 2026 20:00
  static String formatDateTimeShort(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm', 'en_US').format(date);
  }

  /// 🔥 HARI SAJA (Monday)
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
    return formatDay(DateTime.now());
  }

  String formatInboxDate(String? value) {
  if (value == null || value.isEmpty) return '-';

  final date = DateTime.tryParse(value);

  if (date == null) return value;

  final now = DateTime.now();

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
