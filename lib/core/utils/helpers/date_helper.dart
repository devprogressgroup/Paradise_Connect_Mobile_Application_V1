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
