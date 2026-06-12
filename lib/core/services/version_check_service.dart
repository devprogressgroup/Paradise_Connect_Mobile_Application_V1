import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kInstalledVersionKey = 'installed_app_version';

class VersionCheckResult {
  final bool requiresUpdate;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;

  const VersionCheckResult({
    required this.requiresUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
  });
}

class VersionCheckService {
  static Future<String?> getInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kInstalledVersionKey);
  }

  static Future<void> saveInstalledVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInstalledVersionKey, version);
  }

  static Future<VersionCheckResult> check() async {
    if (kIsWeb) {
      return const VersionCheckResult(
        requiresUpdate: false,
        latestVersion: '',
        currentVersion: '',
        downloadUrl: '',
      );
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final savedVersion = await getInstalledVersion();
      if (savedVersion == null) {
        await saveInstalledVersion(currentVersion);
      }

      final latestVersion = ApiConstants.lastVersion;
      final downloadUrl = ApiConstants.appDownloadUrl;

      if (latestVersion.isEmpty) {
        return VersionCheckResult(
          requiresUpdate: false,
          latestVersion: currentVersion,
          currentVersion: currentVersion,
          downloadUrl: downloadUrl,
        );
      }

      final requiresUpdate = _compareVersions(latestVersion.split('+').first, currentVersion) > 0;

      return VersionCheckResult(
        requiresUpdate: requiresUpdate,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return const VersionCheckResult(
        requiresUpdate: false,
        latestVersion: '',
        currentVersion: '',
        downloadUrl: '',
      );
    }
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }
}
