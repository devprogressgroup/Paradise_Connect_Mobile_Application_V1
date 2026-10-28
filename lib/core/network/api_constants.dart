import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:progress_group/core/network/proxy_cipher.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEnvironment { production, development, development2, developmnetDomain }

class _EnvConfig {
  final String label;
  final String baseUrl;
  final String storageUrl;
  final String serverUrl;

  const _EnvConfig({
    required this.label,
    required this.baseUrl,
    required this.storageUrl,
    required this.serverUrl,
  });
}

class ApiConstants {
  static const String _prefKey = 'app_environment';
  static const String _prefSetKey = 'app_environment_user_set';
  static const String _prefDemoKey = 'app_demo_session';

  static const Map<AppEnvironment, _EnvConfig> _configs = {
    AppEnvironment.production: _EnvConfig(
      label: 'Production',
      baseUrl: 'https://api.connect.paradise.id/api',
      storageUrl: 'https://api.connect.paradise.id/storage',
      serverUrl: 'https://api.connect.paradise.id',
    ),

    AppEnvironment.development: _EnvConfig(
      label: 'Development IP',
      baseUrl: 'http://192.168.8.33:1100/api',
      storageUrl: 'http://192.168.8.33:1100/storage',
      serverUrl: 'http://192.168.8.33:1100',
    ),

    AppEnvironment.development2: _EnvConfig(
      label: 'Development 2',
      baseUrl: 'http://172.20.10.13:1100/api',
      storageUrl: 'http://172.20.10.13:1100/storage',
      serverUrl: 'http://172.20.10.13:1100',
    ),
    AppEnvironment.developmnetDomain: _EnvConfig(
      label: 'Development',
      baseUrl: 'https://apidevconnect.paradise.id/api',
      storageUrl: 'https://apidevconnect.paradise.id/storage',
      serverUrl: 'https://apidevconnect.paradise.id',
    ),
  };

  // Akun demo (reviewer App Store/Play) login ke server dev supaya data uji mereka tidak ikut
  // ter-sync ke HubSpot, Google Sheet, dst. SENGAJA di luar [_configs] (tidak muncul di env
  // switcher) dan tujuannya hardcode di sini: setting DEMO_ACCOUNTS di DB cuma menentukan akun
  // MANA yang dialihkan, bukan KE MANA. Lihat DemoAccountService.
  static const _EnvConfig _demoConfig = _EnvConfig(
    label: 'Demo',
    baseUrl: 'https://apidevconnect.paradise.id/api',
    storageUrl: 'https://apidevconnect.paradise.id/storage',
    serverUrl: 'https://apidevconnect.paradise.id',
  );

  static bool _demoSession = false;
  static bool get isDemoSession => _demoSession;

  // Diisi HANYA dari /settings production — DB dev tidak perlu punya DEMO_ACCOUNTS.
  // [demoAccountsFresh] = sudah dapat dari network di sesi app ini (bukan cuma dari cache).
  static Set<String> _demoAccounts = {};
  static bool _demoAccountsFresh = false;
  static bool get demoAccountsFresh => _demoAccountsFresh;
  static String get productionBaseUrl => _configs[AppEnvironment.production]!.baseUrl;

  static bool get _isProductionSource =>
      !_demoSession && _currentEnv == AppEnvironment.production;

  static bool isDemoAccount(String identifier) =>
      _demoAccounts.contains(identifier.trim().toLowerCase());

  /// Selalu menimpa (bukan merge): baris DEMO_ACCOUNTS dihapus/dikosongkan di DB → daftar
  /// ikut kosong, fitur demo mati tanpa update app.
  static void applyDemoAccounts(List<Map<String, dynamic>> productionSettings, {bool fresh = true}) {
    final row = productionSettings.firstWhere(
      (s) => s['setting_name'] == 'DEMO_ACCOUNTS',
      orElse: () => const {},
    );
    final value = row['setting_value'] as String? ?? '';
    _demoAccounts = value
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (fresh) _demoAccountsFresh = true;
  }

  /// SENGAJA tidak menyentuh [envNotifier]: listener-nya me-reset seluruh app (main.dart
  /// _resetApp), yang akan mengosongkan form login di tengah proses login. Request berikutnya
  /// tetap langsung pindah karena DioClient membaca [baseUrl] ulang per request.
  static Future<void> setDemoSession(bool value) async {
    if (_demoSession == value) return;
    _demoSession = value;
    _settingsSignature = null;
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_prefDemoKey, true);
    } else {
      await prefs.remove(_prefDemoKey);
    }
    // Pakai settings terakhir milik server tujuan (kalau ada) sampai fetch berikutnya.
    loadCachedSettings(prefs);
  }

  static AppEnvironment _currentEnv = AppEnvironment.production;
  static final ValueNotifier<AppEnvironment> envNotifier = ValueNotifier(
    AppEnvironment.production,
  );

  static AppEnvironment get currentEnv => _currentEnv;
  static String get envLabel =>
      (_configs[_currentEnv] ?? _configs[AppEnvironment.production]!).label;
  static String labelFor(AppEnvironment env) =>
      (_configs[env] ?? _configs[AppEnvironment.production]!).label;
  static Set<AppEnvironment> get availableEnvironments => _configs.keys.toSet();
  static String baseUrlFor(AppEnvironment env) => _configs[env]?.baseUrl ?? '';

  static void loadFromPrefs(SharedPreferences prefs) {
    _demoSession = prefs.getBool(_prefDemoKey) ?? false;
    final userSet = prefs.getBool(_prefSetKey) ?? false;
    if (!userSet) {
      _currentEnv = AppEnvironment.production;
      envNotifier.value = _currentEnv;
      return;
    }
    final saved = prefs.getString(_prefKey);
    final parsed = switch (saved) {
      'development' => AppEnvironment.development,
      'development2' => AppEnvironment.development2,
      'productionDomain' => AppEnvironment.developmnetDomain,
      _ => AppEnvironment.production,
    };
    _currentEnv = _configs.containsKey(parsed)
        ? parsed
        : AppEnvironment.production;
    envNotifier.value = _currentEnv;
  }

  static Future<void> switchEnv(AppEnvironment env) async {
    _currentEnv = env;
    _demoSession = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDemoKey);
    final key = switch (env) {
      AppEnvironment.development => 'development',
      AppEnvironment.development2 => 'development2',
      AppEnvironment.developmnetDomain => 'productionDomain',
      AppEnvironment.production => 'production',
    };
    await prefs.setString(_prefKey, key);
    await prefs.setBool(_prefSetKey, true);
    envNotifier.value = env;
  }

  static _EnvConfig get _config => _demoSession
      ? _demoConfig
      : _configs[_currentEnv] ?? _configs[AppEnvironment.production]!;

  static String get baseUrl => _config.baseUrl;
  static String get storageUrl => _config.storageUrl;
  static String get serverUrl => _config.serverUrl;
  static const String analyticsEventsEndpoint = '/analytics-events';

  static String _waServerUrl = '';
  static String _salesbookWebhookUrl = '';
  static String _salesbookWebhookToken = '';
  static String _landingPageUrl = '';
  static String _siapHuniUrl = '';
  static String _lastVersion = '';
  static String _appDownloadUrl = '';
  static String _saleskitUrl = '';
  static String _loginHelpMessage = '';
  static String _prospectStatusDefaultRangePreset = '';
  static String _prospectStatusApptRangePreset = '';
  static String _prospectStatusVisitRangePreset = '';
  static String _prospectStatusReserveRangePreset = '';
  static String _prospectStatusSpRangePreset = '';
  static String _prospectStatusLostRangePreset = '';
  static final ValueNotifier<int> settingsVersion = ValueNotifier<int>(0);

  static String get waServerURL => _waServerUrl;
  static String get salesbookWebhookUrl => _salesbookWebhookUrl;
  static String get salesbookWebhookToken => _salesbookWebhookToken;
  static String get landingPageUrl => _landingPageUrl;
  static String get siapHuniUrl => _siapHuniUrl;
  static String get lastVersion => _lastVersion;
  static String get appDownloadUrl => _appDownloadUrl;
  static String get saleskitUrl => _saleskitUrl;
  static String get loginHelpMessage => _loginHelpMessage;
  static String get prospectStatusDefaultRangePreset =>
      _prospectStatusDefaultRangePreset;
  static String get prospectStatusApptRangePreset =>
      _prospectStatusApptRangePreset;
  static String get prospectStatusVisitRangePreset =>
      _prospectStatusVisitRangePreset;
  static String get prospectStatusReserveRangePreset =>
      _prospectStatusReserveRangePreset;
  static String get prospectStatusSpRangePreset => _prospectStatusSpRangePreset;
  static String get prospectStatusLostRangePreset =>
      _prospectStatusLostRangePreset;

  // Cache /settings per environment supaya main() tidak perlu nunggu network sebelum runApp():
  // nilai terakhir langsung dipakai dari prefs, lalu fetch terbaru jalan di background.
  static String get _settingsCacheKey =>
      _demoSession ? 'cached_settings_demo' : 'cached_settings_${_currentEnv.name}';
  static String? _settingsSignature;

  static void loadCachedSettings(SharedPreferences prefs) {
    final raw = ProxyCipher.decryptString(prefs.getString(_settingsCacheKey));
    if (raw == null) return;
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
      _applySettingValues(list);
      if (_isProductionSource) applyDemoAccounts(list, fresh: false);
      _settingsSignature = raw;
    } catch (_) {}
  }

  /// Terapkan hasil GET /settings. Kalau isinya sama dengan yang sudah terpasang (mis. dari
  /// cache), tidak melakukan apa-apa — supaya listener [settingsVersion] (Home, Contact)
  /// tidak reload data tanpa alasan tiap kali settings di-fetch ulang.
  static void applySettings(List<Map<String, dynamic>> settings) {
    // Sebelum cek signature: isi sama dengan cache tetap berarti daftar demo sudah "fresh".
    if (_isProductionSource) applyDemoAccounts(settings);
    final signature = jsonEncode(settings);
    if (signature == _settingsSignature) return;
    _settingsSignature = signature;
    _applySettingValues(settings);
    final cacheKey = _settingsCacheKey;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(cacheKey, ProxyCipher.encryptString(signature)))
        .catchError((_) => false);
    settingsVersion.value++;
  }

  static void _applySettingValues(List<Map<String, dynamic>> settings) {
    for (final s in settings) {
      final name = s['setting_name'] as String?;
      final value = s['setting_value'] as String?;
      if (name == null || value == null || value.isEmpty) continue;
      switch (name) {
        case 'WA_SERVER_URL':
          _waServerUrl = value;
        case 'SALESBOOK_URL':
          _salesbookWebhookUrl = value;
        case 'X-App-Token SalesBook':
          _salesbookWebhookToken = value;
        case 'LANDING_PAGE_URL':
          _landingPageUrl = value;
        case 'SIAP_HUNI_URL':
          _siapHuniUrl = value;
        case 'LAST_VERSION':
          _lastVersion = value;
        case 'APP_DOWNLOAD_URL':
          _appDownloadUrl = value;
        case 'SALESKIT_URL':
          _saleskitUrl = value;
        case 'LOGIN_HELP_MESSAGE':
          _loginHelpMessage = value;
        case 'PROSPECT_STATUS_DEFAULT_RANGE_PRESET':
          _prospectStatusDefaultRangePreset = value;
        case 'PROSPECT_STATUS_APPT_RANGE_PRESET':
          _prospectStatusApptRangePreset = value;
        case 'PROSPECT_STATUS_VISIT_RANGE_PRESET':
          _prospectStatusVisitRangePreset = value;
        case 'PROSPECT_STATUS_RESERVE_RANGE_PRESET':
          _prospectStatusReserveRangePreset = value;
        case 'PROSPECT_STATUS_SP_RANGE_PRESET':
          _prospectStatusSpRangePreset = value;
        case 'PROSPECT_STATUS_LOST_RANGE_PRESET':
          _prospectStatusLostRangePreset = value;
      }
    }
  }

  static String townshipImageUrl(String slug, String fileName) =>
      '$_saleskitUrl/bin/db/images/township/$slug/$fileName';

  static String clusterImageUrl(String townshipSlug, String fileName) =>
      '$_saleskitUrl/bin/db/images/cluster/$townshipSlug/$fileName';

  static String commercialImageUrl(String filePath) =>
      filePath.startsWith('bin/db/')
      ? '$_saleskitUrl/$filePath'
      : '$_saleskitUrl/bin/db/images/commercial/$filePath';
}
