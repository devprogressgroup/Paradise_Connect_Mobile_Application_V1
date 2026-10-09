import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _playStoreInstaller = 'com.android.vending';

/// Update untuk app yang di-install dari Google Play, lewat Play In-App Updates (mode immediate).
/// OTA APK (ota_update_service.dart) tidak bisa dipakai untuk app dari Play: app-nya ditandatangani
/// key Play App Signing, jadi APK hasil build sendiri ditolak Android karena signature beda.
class PlayUpdateService {
  static bool? _fromPlayStore;

  static Future<bool> isFromPlayStore() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_fromPlayStore != null) return _fromPlayStore!;
    try {
      final info = await PackageInfo.fromPlatform();
      _fromPlayStore = info.installerStore == _playStoreInstaller;
    } catch (_) {
      _fromPlayStore = false;
    }
    return _fromPlayStore!;
  }

  /// True kalau Play punya versi lebih baru, termasuk update immediate yang sempat terputus
  /// (mis. app di-kill di tengah download) — keduanya harus diselesaikan dulu.
  static Future<bool> isUpdateAvailable() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress;
    } catch (_) {
      return false;
    }
  }

  /// Buka layar update full-screen milik Play. Kalau sukses, Play me-restart app sendiri,
  /// jadi hasil yang sampai ke caller praktis cuma userDeniedUpdate / inAppUpdateFailed.
  static Future<AppUpdateResult> startImmediateUpdate() async {
    try {
      // performImmediateUpdate butuh AppUpdateInfo dari checkForUpdate di proses yang sama.
      final info = await InAppUpdate.checkForUpdate();
      if (!info.immediateUpdateAllowed) return AppUpdateResult.inAppUpdateFailed;
      return await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Fallback kalau flow in-app gagal: buka halaman app di aplikasi Play Store.
  static Future<void> openStoreListing() async {
    try {
      final packageName = (await PackageInfo.fromPlatform()).packageName;
      final opened = await launchUrl(
        Uri.parse('market://details?id=$packageName'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$packageName'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
