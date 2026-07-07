import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpersonationManager {
  ImpersonationManager._();

  static const _flagKey = 'is_impersonating';
  static const _nameKey = 'impersonating_name';

  static SharedPreferences? _prefs;


  static final ValueNotifier<String?> nameNotifier = ValueNotifier<String?>(null);

  static bool get isActive => nameNotifier.value != null;
  static String? get targetName => nameNotifier.value;


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
