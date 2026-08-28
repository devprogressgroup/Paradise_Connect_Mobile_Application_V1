import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _channel = MethodChannel('com.example.progress_group/install_apk');

class OldAppCheckService {
  static const String oldPackageName = 'com.example.progress_group';

  static final ValueNotifier<bool> detectedNotifier = ValueNotifier<bool>(false);

  static Future<void> check() async {
    if (kIsWeb || !Platform.isAndroid) return;
    detectedNotifier.value = await isOldAppInstalled();
  }

  static Future<bool> isOldAppInstalled() async {
    try {
      // Build dev pakai applicationId yang sama persis dengan oldPackageName (lihat
      // dev-branch-applicationid-separation.md) — tanpa guard ini, app dev bakal
      // mendeteksi dirinya sendiri sebagai "app lama" dan nyuruh uninstall diri sendiri.
      final self = await PackageInfo.fromPlatform();
      if (self.packageName == oldPackageName) return false;
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': oldPackageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Return null on success, atau pesan error kalau gagal (dipakai UI buat tampilin SnackBar).
  static Future<String?> openUninstallOldApp() async {
    try {
      await _channel.invokeMethod('uninstallPackage', {'packageName': oldPackageName});
      return null;
    } on PlatformException catch (e) {
      return '${e.code}: ${e.message}';
    }
  }
}
