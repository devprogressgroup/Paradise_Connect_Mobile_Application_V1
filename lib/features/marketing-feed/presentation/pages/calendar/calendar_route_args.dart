import 'package:intl/intl.dart';

/// Query route form Postingan / Polling / Link saat dibuka dari Kalender Jadwal.
/// `source=calendar` = kiriman baru dari kalender (lewat jalur moderator, tidak lewat review sales);
/// `at` = waktu tayang awal dalam jam dinding WIB, format yyyy-MM-dd HH:mm.
class FeedCalendarRouteArgs {
  FeedCalendarRouteArgs._();

  static const sourceKey = 'source';
  static const sourceCalendar = 'calendar';
  static const atKey = 'at';

  static final _atFormat = DateFormat('yyyy-MM-dd HH:mm');

  static Map<String, String> forSchedule(DateTime at) => {
    sourceKey: sourceCalendar,
    atKey: _atFormat.format(at),
  };

  static bool isFromCalendar(Map<String, String> query) =>
      query[sourceKey] == sourceCalendar;

  /// Jam dinding WIB sebagai DateTime UTC-flag (konvensi FeedScheduleField). Null kalau kosong / tidak valid.
  static DateTime? parseAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
    );
  }
}
