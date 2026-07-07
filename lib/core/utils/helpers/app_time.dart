import 'package:intl/intl.dart';

/// Sumber waktu "resmi" aplikasi, disinkronkan dari header `Date` pada
/// response server (bukan dari jam perangkat). Menggunakan [Stopwatch]
/// (jam monotonic) sebagai penanda waktu berlalu, sehingga hasil [now]
/// tidak berubah meski user mengubah setelan tanggal/jam di HP-nya.
class AppTime {
  AppTime._();

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static DateTime? _syncedServerTimeUtc;
  static int _syncedElapsedMs = 0;

  static final DateFormat _httpDateFormat =
      DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

  /// Dipanggil setiap ada response dari server (lihat DioClient) dengan
  /// nilai header `date` mentah, contoh: "Wed, 21 Oct 2015 07:28:00 GMT".
  static void syncFromHeader(String? httpDateHeader) {
    if (httpDateHeader == null || httpDateHeader.isEmpty) return;
    try {
      final parsed = _httpDateFormat.parseUtc(httpDateHeader);
      _syncedServerTimeUtc = parsed;
      _syncedElapsedMs = _stopwatch.elapsedMilliseconds;
    } catch (_) {
      // Header tidak sesuai format, abaikan dan pertahankan sinkronisasi terakhir.
    }
  }

  static bool get hasSynced => _syncedServerTimeUtc != null;

  /// Waktu sekarang versi server (waktu nasional), bukan jam perangkat.
  /// Sebelum sinkronisasi pertama berhasil (mis. sebelum ada respons API),
  /// jatuh kembali ke jam perangkat sebagai fallback sementara.
  static DateTime now() {
    final synced = _syncedServerTimeUtc;
    if (synced == null) return DateTime.now();
    final elapsedSinceSync = _stopwatch.elapsedMilliseconds - _syncedElapsedMs;
    return synced.add(Duration(milliseconds: elapsedSinceSync)).toLocal();
  }

  static const Duration _driftThreshold = Duration(minutes: 2);
  static bool _warnedThisSession = false;

  /// Selisih jam perangkat terhadap waktu server. Null bila belum pernah sinkron.
  static Duration? get deviceDrift {
    final synced = _syncedServerTimeUtc;
    if (synced == null) return null;
    final elapsedSinceSync = _stopwatch.elapsedMilliseconds - _syncedElapsedMs;
    final serverNowUtc = synced.add(Duration(milliseconds: elapsedSinceSync));
    return DateTime.now().toUtc().difference(serverNowUtc);
  }

  /// True hanya SEKALI per sesi app, tepat saat drift jam perangkat vs server
  /// pertama kali terdeteksi melewati ambang batas — dipakai untuk memicu
  /// peringatan "jangan set tanggal/jam manual" tanpa spam tiap request.
  static bool consumeSuspiciousDriftFlag() {
    final drift = deviceDrift;
    if (drift == null || _warnedThisSession) return false;
    if (drift.abs() >= _driftThreshold) {
      _warnedThisSession = true;
      return true;
    }
    return false;
  }
}
