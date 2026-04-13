import 'package:intl/intl.dart';

class DateHelper {

  /// 🔥 FULL (April 13, 2026 08:30 AM)
  static String formatFull(DateTime date) {
    return DateFormat('MMMM d, yyyy hh:mm a', 'en_US').format(date);
  }

  static String nowFull() {
    return formatFull(DateTime.now());
  }

  /// 🔥 JAM SAJA (08:30 AM)
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'en_US').format(date);
  }

  static String nowTime() {
    return formatTime(DateTime.now());
  }

  /// 🔥 TANGGAL SAJA (April 13, 2026)
  static String formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy', 'en_US').format(date);
  }

  static String nowDate() {
    return formatDate(DateTime.now());
  }

  /// 🔥 HARI + TANGGAL (Monday, April 13, 2026)
  static String formatDayDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy', 'en_US').format(date);
  }

  static String nowDayDate() {
    return formatDayDate(DateTime.now());
  }

  /// 🔥 HARI SAJA (Monday)
  static String formatDay(DateTime date) {
    return DateFormat('EEEE', 'en_US').format(date);
  }

  static String nowDay() {
    return formatDay(DateTime.now());
  }
}