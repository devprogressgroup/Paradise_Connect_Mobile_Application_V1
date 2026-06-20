import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State global "sedang impersonate" (superadmin login-as user lain).
///
/// - [nameNotifier] dipakai banner global untuk tahu apakah sedang impersonate
///   dan sebagai siapa. null = tidak sedang impersonate.
/// - State di-persist ke SharedPreferences agar bertahan saat app restart
///   (token admin asli juga di-stash di AuthLocalDataSource, key impersonator_token),
///   sehingga tombol "Keluar" tetap berfungsi setelah app dibuka ulang.
class ImpersonationManager {
  ImpersonationManager._();

  static const _flagKey = 'is_impersonating';
  static const _nameKey = 'impersonating_name';

  static SharedPreferences? _prefs;

  /// Notifier nama user yang sedang di-impersonate (null = tidak aktif).
  static final ValueNotifier<String?> nameNotifier = ValueNotifier<String?>(null);

  static bool get isActive => nameNotifier.value != null;
  static String? get targetName => nameNotifier.value;

  /// Dipanggil sekali di main() untuk rehydrate state dari prefs.
  static void bind(SharedPreferences prefs) {
    _prefs = prefs;
    final active = prefs.getBool(_flagKey) ?? false;
    nameNotifier.value = active ? prefs.getString(_nameKey) : null;
  }

  static Future<void> start(String targetName) async {
    await _prefs?.setBool(_flagKey, true);
    await _prefs?.setString(_nameKey, targetName);
    nameNotifier.value = targetName;
  }

  static Future<void> stop() async {
    await _prefs?.remove(_flagKey);
    await _prefs?.remove(_nameKey);
    nameNotifier.value = null;
  }
}
