import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEnvironment { production, development, development2, productionDomain }

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
      label: 'Development',
      baseUrl: 'http://192.168.8.36:8000/api',
      storageUrl: 'http://192.168.8.36:8000/storage',
      serverUrl: 'http://192.168.8.36:8000',
    ),

    AppEnvironment.development2: _EnvConfig(
      label: 'Development 2',
      baseUrl: 'http://192.168.18.150:8000/api',
      storageUrl: 'http://192.168.18.150:8000/storage',
      serverUrl: 'http://192.168.18.150:8000',
    ),


    AppEnvironment.productionDomain: _EnvConfig(
      label: 'Production Domain',
      baseUrl: 'https://apidevconnect.paradise.id/api',
      storageUrl: 'https://apidevconnect.paradise.id/storage',
      serverUrl: 'https://apidevconnect.paradise.id',
    ),
  };




  static AppEnvironment _currentEnv = AppEnvironment.production;
  static final ValueNotifier<AppEnvironment> envNotifier = ValueNotifier(AppEnvironment.production);

  static AppEnvironment get currentEnv => _currentEnv;
  static String get envLabel => _configs[_currentEnv]!.label;

  static void loadFromPrefs(SharedPreferences prefs) {
    final userSet = prefs.getBool(_prefSetKey) ?? false;
    if (!userSet) {
      _currentEnv = AppEnvironment.production;
      envNotifier.value = _currentEnv;
      return;
    }
    final saved = prefs.getString(_prefKey);
    _currentEnv = switch (saved) {
      'development' => AppEnvironment.development,
      'development2' => AppEnvironment.development2,
      'productionDomain' => AppEnvironment.productionDomain,
      _ => AppEnvironment.production,
    };
    envNotifier.value = _currentEnv;
  }

  static Future<void> switchEnv(AppEnvironment env) async {
    _currentEnv = env;
    final prefs = await SharedPreferences.getInstance();
    final key = switch (env) {
      AppEnvironment.development => 'development',
      AppEnvironment.development2 => 'development2',
      AppEnvironment.productionDomain => 'productionDomain',
      AppEnvironment.production => 'production',
    };
    await prefs.setString(_prefKey, key);
    await prefs.setBool(_prefSetKey, true);
    envNotifier.value = env;
  }

  static _EnvConfig get _config => _configs[_currentEnv]!;

  // static String get baseUrl => (kIsWeb && _currentEnv == AppEnvironment.productionDomain)
  //     ? 'https://devconnect.paradise.id/proxy/api'
  //     : _config.baseUrl;
  // static String get storageUrl => (kIsWeb && _currentEnv == AppEnvironment.productionDomain)
  //     ? 'https://devconnect.paradise.id/proxy/storage'
  //     : _config.storageUrl;
  // static String get serverUrl => (kIsWeb && _currentEnv == AppEnvironment.productionDomain)
  //     ? 'https://devconnect.paradise.id/proxy'
  //     : _config.serverUrl;
  static String get baseUrl => _config.baseUrl;
  static String get storageUrl => _config.storageUrl;
  static String get serverUrl => _config.serverUrl;


  // Dynamic settings — loaded from /api/settings on startup, fallback to hardcoded defaults
  static String _waServerUrl = '';
  static String _salesbookWebhookUrl = '';
  static String _salesbookWebhookToken = '';
  static String _siteplanBaseUrl = '';
  static String _siteplanToken = '';
  static String _landingPageUrl = '';
  static String _lastVersion = '';
  static String _appDownloadUrl = '';
  static String _saleskitUrl = '';

  static String get waServerURL => _waServerUrl;
  static String get salesbookWebhookUrl => _salesbookWebhookUrl;
  static String get salesbookWebhookToken => _salesbookWebhookToken;
  static String get siteplanBaseUrl => _siteplanBaseUrl;
  static Map<String, String> get siteplanWebviewHeaders => {'X-App-Token': _siteplanToken};
  static String get landingPageUrl => _landingPageUrl;
  static String get lastVersion => _lastVersion;
  static String get appDownloadUrl => _appDownloadUrl;
  static String get saleskitUrl => _saleskitUrl;

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
        case 'SITEPLAN_MOBILE_URL':
          _siteplanBaseUrl = value;
        case 'X-App-Token SitePlan':
          _siteplanToken = value;
        case 'LANDING_PAGE_URL':
          _landingPageUrl = value;
        case 'LAST_VERSION':
          _lastVersion = value;
        case 'APP_DOWNLOAD_URL':
          _appDownloadUrl = value;
        case 'SALESKIT_URL':
          _saleskitUrl = value;
      }
    }
  }

  static String townshipImageUrl(String slug, String fileName) => '$_saleskitUrl/bin/db/images/township/$slug/$fileName';

  static String clusterImageUrl(String townshipSlug, String fileName) => '$_saleskitUrl/bin/db/images/cluster/$townshipSlug/$fileName';

  static String commercialImageUrl(String filePath) => filePath.startsWith('bin/db/') ? '$_saleskitUrl/$filePath' : '$_saleskitUrl/bin/db/images/commercial/$filePath';

}
