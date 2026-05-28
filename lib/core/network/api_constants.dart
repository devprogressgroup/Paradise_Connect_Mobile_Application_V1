import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEnvironment { production, development, development2 }

class _EnvConfig {
  final String label;
  final String baseUrl;
  final String storageUrl;
  final String waServerURL;
  final String serverUrl;

  const _EnvConfig({
    required this.label,
    required this.baseUrl,
    required this.storageUrl,
    required this.waServerURL,
    required this.serverUrl,
  });
}

class ApiConstants {
  static const String _prefKey = 'app_environment';

  static const Map<AppEnvironment, _EnvConfig> _configs = {
    AppEnvironment.production: _EnvConfig(
      label: 'Production',
      baseUrl: 'http://192.168.8.21:9090/api',
      storageUrl: 'http://192.168.8.21:9090/storage',
      waServerURL: 'http://192.168.8.40:3000',
      serverUrl: 'http://192.168.8.21:9090',
    ),
    AppEnvironment.development: _EnvConfig(
      label: 'Development',
      baseUrl: 'http://192.168.8.38:8000/api',
      storageUrl: 'http://192.168.8.38:8000/storage',
      waServerURL: 'http://192.168.8.38:3000',
      serverUrl: 'http://192.168.8.38:8000',
    ),
    AppEnvironment.development2: _EnvConfig(
      label: 'Development 2',
      baseUrl: 'http://172.20.10.3:8000/api',
      storageUrl: 'http://172.20.10.3:8000/storage',
      waServerURL: 'http://172.20.10.3:3000',
      serverUrl: 'http://172.20.10.3:8000',
    ),
  };




  static AppEnvironment _currentEnv = AppEnvironment.production;
  static final ValueNotifier<AppEnvironment> envNotifier = ValueNotifier(AppEnvironment.production);

  static AppEnvironment get currentEnv => _currentEnv;
  static String get envLabel => _configs[_currentEnv]!.label;

  static void loadFromPrefs(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    _currentEnv = switch (saved) {
      'development' => AppEnvironment.development,
      'development2' => AppEnvironment.development2,
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
      AppEnvironment.production => 'production',
    };
    await prefs.setString(_prefKey, key);
    envNotifier.value = env;
  }

  static _EnvConfig get _config => _configs[_currentEnv]!;

  static String get baseUrl => _config.baseUrl;
  static String get storageUrl => _config.storageUrl;
  static String get waServerURL => _config.waServerURL;
  static String get serverUrl => _config.serverUrl;

  static const String paradiseUrl = 'https://paradise.co.id';

  static String townshipImageUrl(String slug, String fileName) =>'$paradiseUrl/bin/db/images/township/$slug/$fileName';

  static String clusterImageUrl(String townshipSlug, String fileName) =>'$paradiseUrl/bin/db/images/cluster/$townshipSlug/$fileName';

  static String commercialImageUrl(String filePath) => filePath.startsWith('bin/db/') ? '$paradiseUrl/$filePath' : '$paradiseUrl/bin/db/images/commercial/$filePath';
}
