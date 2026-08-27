import 'package:flutter/foundation.dart';
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

  static const Map<AppEnvironment, _EnvConfig> _configs = {
    AppEnvironment.production: _EnvConfig(
      label: 'Production',
      baseUrl: 'https://api.connect.paradise.id/api',
      storageUrl: 'https://api.connect.paradise.id/storage',
      serverUrl: 'https://api.connect.paradise.id',
    
    ),


    AppEnvironment.development: _EnvConfig(
      label: 'Development IP',
      baseUrl: 'http://192.168.8.67:8000/api',
      storageUrl: 'http://192.168.8.67:8000/storage',
      serverUrl: 'http://192.168.8.67:8000',
    ),

    // AppEnvironment.development2: _EnvConfig(
    //   label: 'Development 2',
    //   baseUrl: 'http://172.20.10.2:8000/api',
    //   storageUrl: 'http://172.20.10.2:8000/storage',
    //   serverUrl: 'http://172.20.10.2:8000',
    // ),


    AppEnvironment.developmnetDomain: _EnvConfig(
      label: 'Development',
      baseUrl: 'https://apidevconnect.paradise.id/api',
      storageUrl: 'https://apidevconnect.paradise.id/storage',
      serverUrl: 'https://apidevconnect.paradise.id',
    ),
  };




  static AppEnvironment _currentEnv = AppEnvironment.production;
  static final ValueNotifier<AppEnvironment> envNotifier = ValueNotifier(AppEnvironment.production);

  static AppEnvironment get currentEnv => _currentEnv;
  static String get envLabel => (_configs[_currentEnv] ?? _configs[AppEnvironment.production]!).label;
  static String labelFor(AppEnvironment env) => (_configs[env] ?? _configs[AppEnvironment.production]!).label;
  static Set<AppEnvironment> get availableEnvironments => _configs.keys.toSet();
  static String baseUrlFor(AppEnvironment env) => _configs[env]?.baseUrl ?? '';

  static void loadFromPrefs(SharedPreferences prefs) {
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
    _currentEnv = _configs.containsKey(parsed) ? parsed : AppEnvironment.production;
    envNotifier.value = _currentEnv;
  }

  static Future<void> switchEnv(AppEnvironment env) async {
    _currentEnv = env;
    final prefs = await SharedPreferences.getInstance();
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

  static _EnvConfig get _config => _configs[_currentEnv] ?? _configs[AppEnvironment.production]!;

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
  static String get prospectStatusDefaultRangePreset => _prospectStatusDefaultRangePreset;
  static String get prospectStatusApptRangePreset => _prospectStatusApptRangePreset;
  static String get prospectStatusVisitRangePreset => _prospectStatusVisitRangePreset;
  static String get prospectStatusReserveRangePreset => _prospectStatusReserveRangePreset;
  static String get prospectStatusSpRangePreset => _prospectStatusSpRangePreset;
  static String get prospectStatusLostRangePreset => _prospectStatusLostRangePreset;

  static void applySettings(List<Map<String, dynamic>> settings) {
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
    settingsVersion.value++;
  }

  static String townshipImageUrl(String slug, String fileName) => '$_saleskitUrl/bin/db/images/township/$slug/$fileName';

  static String clusterImageUrl(String townshipSlug, String fileName) => '$_saleskitUrl/bin/db/images/cluster/$townshipSlug/$fileName';

  static String commercialImageUrl(String filePath) => filePath.startsWith('bin/db/') ? '$_saleskitUrl/$filePath' : '$_saleskitUrl/bin/db/images/commercial/$filePath';

}

