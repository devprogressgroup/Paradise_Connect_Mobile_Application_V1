import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': oldPackageName},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[OldAppCheckService] isPackageInstalled failed: ${e.message}');
      return false;
    }
  }

  /// Return null on success, atau pesan error kalau gagal (dipakai UI buat tampilin SnackBar).
  static Future<String?> openUninstallOldApp() async {
    try {
      await _channel.invokeMethod('uninstallPackage', {'packageName': oldPackageName});
      return null;
    } on PlatformException catch (e) {
      final message = '${e.code}: ${e.message}';
      debugPrint('[OldAppCheckService] uninstallPackage failed: $message');
      return message;
    }
  }
}
