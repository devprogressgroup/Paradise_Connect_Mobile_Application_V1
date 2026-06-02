import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
  /// Ambil versi yang tersimpan di lokal (dari install terakhir)
  static Future<String?> getInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kInstalledVersionKey);
  }

  /// Simpan versi ke lokal — dipanggil saat pertama install atau setelah update
  static Future<void> saveInstalledVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInstalledVersionKey, version);
  }

  static Future<VersionCheckResult> check() async {
    debugPrint('[VersionCheck] check() dipanggil');
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      // Pertama kali install → simpan versi ke lokal
      final savedVersion = await getInstalledVersion();
      if (savedVersion == null) {
        await saveInstalledVersion(currentVersion);
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {"Accept": "application/json"},
      ));

      final response = await dio.get('/app-version');
      final data = response.data;

      if (data['status'] != true) {
        return VersionCheckResult(
          requiresUpdate: false,
          latestVersion: currentVersion,
          currentVersion: currentVersion,
          downloadUrl: '',
        );
      }

      final latestVersion = data['data']['version'] as String;
      final downloadUrl = (data['data']['download_url'] as String?) ?? '';

      // Bandingkan versi server vs versi yang terinstall saat ini
      final requiresUpdate = _compareVersions(latestVersion, currentVersion) > 0;

      debugPrint('┌─── Version Check ────────────────────');
      debugPrint('│ 📱 Versi app           : $currentVersion');
      debugPrint('│ 💾 Versi lokal (prefs) : ${savedVersion ?? "(baru install)"}');
      debugPrint('│ 🌐 Versi server (API)  : $latestVersion');
      debugPrint('│ 🔔 Ada update?         : ${requiresUpdate ? "YA → popup muncul" : "TIDAK → lanjut normal"}');
      debugPrint('└──────────────────────────────────────');

      return VersionCheckResult(
        requiresUpdate: requiresUpdate,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('[VersionCheck] ERROR: $e');
      return VersionCheckResult(
        requiresUpdate: false,
        latestVersion: '',
        currentVersion: '',
        downloadUrl: '',
      );
    }
  }

  /// Positif jika [a] > [b], negatif jika [a] < [b], 0 jika sama
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
