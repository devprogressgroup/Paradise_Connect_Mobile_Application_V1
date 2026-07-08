import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_group/core/network/analytics_events_remote_datasource.dart';

class AnalyticsService {
  AnalyticsService._();

  static const String _prefKey = 'analytics_enabled_events';

  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: instance);

  // userId disimpan lokal agar bisa disertakan di setiap event
  static String? _currentUserId;
  static String? _currentRole;

  // event_key yang is_enabled == true, dimuat dari GET /analytics-events
  static Set<String> _enabledEventKeys = {};

  static void loadFromPrefs(SharedPreferences prefs) {
    final saved = prefs.getStringList(_prefKey);
    if (saved != null) _enabledEventKeys = saved.toSet();
  }

  static Future<void> refreshEnabledEvents(Dio dio) async {
    final events = await AnalyticsEventsRemoteDataSource(dio).getAnalyticsEvents();
    if (events.isEmpty) return;
    final enabled = events
        .where((e) => e['is_enabled'] == true)
        .map((e) => e['event_key'] as String)
        .toSet();
    _enabledEventKeys = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, enabled.toList());
  }

  static bool isEnabled(String eventKey) => _enabledEventKeys.contains(eventKey);

  // --- Generic gated event ---
  static Future<void> logEvent(String eventKey, {Map<String, Object>? parameters}) {
    if (!isEnabled(eventKey)) return Future.value();
    return instance.logEvent(
      name: eventKey,
      parameters: {
        ...?parameters,
        if (_currentUserId != null) 'user_id': _currentUserId!,
        if (_currentRole != null) 'role': _currentRole!,
      },
    );
  }

  // --- Auth Events ---
  static Future<void> logLogin({String method = 'email'}) =>
      instance.logLogin(loginMethod: method);

  static Future<void> logLogout() =>
      instance.logEvent(name: 'logout');

  // --- Screen View (di-gate oleh event_key screen yang sama dengan namanya) ---
  static Future<void> logScreenView(String screenName) {
    if (!isEnabled(screenName)) return Future.value();
    return instance.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // --- User Properties ---
  static Future<void> setUserProperties({
    required String userId,
    String? role,
  }) async {
    _currentUserId = userId;
    _currentRole = role;
    await instance.setUserId(id: userId);
    if (role != null) {
      await instance.setUserProperty(name: 'user_role', value: role);
    }
  }

  static Future<void> clearUser() async {
    _currentUserId = null;
    _currentRole = null;
    await instance.setUserId(id: null);
    await instance.setUserProperty(name: 'user_role', value: null);
  }
}
