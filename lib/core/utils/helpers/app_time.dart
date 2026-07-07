import 'package:intl/intl.dart';
class AppTime {
  AppTime._();

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static DateTime? _syncedServerTimeUtc;
  static int _syncedElapsedMs = 0;

  static final DateFormat _httpDateFormat =
      DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

  static void syncFromHeader(String? httpDateHeader) {
    if (httpDateHeader == null || httpDateHeader.isEmpty) return;
    try {
      final parsed = _httpDateFormat.parseUtc(httpDateHeader);
      _syncedServerTimeUtc = parsed;
      _syncedElapsedMs = _stopwatch.elapsedMilliseconds;
    } catch (_) {
    }
  }

  static bool get hasSynced => _syncedServerTimeUtc != null;

  static DateTime now() {
    final synced = _syncedServerTimeUtc;
    if (synced == null) return DateTime.now();
    final elapsedSinceSync = _stopwatch.elapsedMilliseconds - _syncedElapsedMs;
    return synced.add(Duration(milliseconds: elapsedSinceSync)).toLocal();
  }

  static const Duration _driftThreshold = Duration(minutes: 2);
  static bool _warnedThisSession = false;

  static Duration? get deviceDrift {
    final synced = _syncedServerTimeUtc;
    if (synced == null) return null;
    final elapsedSinceSync = _stopwatch.elapsedMilliseconds - _syncedElapsedMs;
    final serverNowUtc = synced.add(Duration(milliseconds: elapsedSinceSync));
    return DateTime.now().toUtc().difference(serverNowUtc);
  }

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
