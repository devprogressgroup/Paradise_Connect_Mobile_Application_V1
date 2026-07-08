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

  /// Sync from the server's epoch-ms time embedded directly in a response
  /// body (see `GatewayController`'s `t` field). Unlike the HTTP `Date`
  /// header, response body content is always readable by web/PWA regardless
  /// of CORS header-exposure config, so this is the more reliable source and
  /// is applied last (it overrides a header-based sync when both are present).
  static void syncFromServerMillis(int? serverEpochMs) {
    if (serverEpochMs == null) return;
    _syncedServerTimeUtc = DateTime.fromMillisecondsSinceEpoch(serverEpochMs, isUtc: true);
    _syncedElapsedMs = _stopwatch.elapsedMilliseconds;
  }

  static const Duration _wibOffset = Duration(hours: 7);

  static DateTime _correctedUtcInstant() {
    final synced = _syncedServerTimeUtc;
    if (synced == null) return DateTime.now().toUtc();
    final elapsedSinceSync = _stopwatch.elapsedMilliseconds - _syncedElapsedMs;
    return synced.add(Duration(milliseconds: elapsedSinceSync));
  }

  /// True corrected UTC instant (server-synced when available). Use this for
  /// real epoch/timestamp needs (e.g. request signing) — never for display.
  static DateTime nowUtcInstant() => _correctedUtcInstant();

  /// Wall-clock time in WIB (Asia/Jakarta, UTC+7), used app-wide so web/PWA
  /// matches mobile regardless of the device/browser's own timezone setting.
  static DateTime now() => _correctedUtcInstant().add(_wibOffset);

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
