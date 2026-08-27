import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('com.example.progress_group/install_apk');

class OtaUpdateService {
  static CancelToken? _cancelToken;

  static Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
    required void Function() onInstalling,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    if (downloadUrl.isEmpty) {
      debugPrint('[OtaUpdateService] downloadUrl kosong, batal download');
      onError('URL unduhan tidak tersedia. Hubungi admin.');
      return;
    }

    _cancelToken = CancelToken();

    try {
      debugPrint('[OtaUpdateService] mulai download dari $downloadUrl');
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/pg_update.apk';

      final file = File(savePath);
      if (await file.exists()) await file.delete();

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));

      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          } else {
            const estimatedTotal = 15 * 1024 * 1024;
            onProgress((received / estimatedTotal).clamp(0.0, 0.95));
          }
        },
      );

      debugPrint('[OtaUpdateService] download selesai, buka installer: $savePath');
      onInstalling();

      await _channel.invokeMethod('installApk', {'filePath': savePath});
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      debugPrint('[OtaUpdateService] DioException: ${e.type} - ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          onError('Download gagal: Koneksi bermasalah. Silakan periksa jaringan Anda dan coba lagi.');
          break;
        default:
          onError('Download gagal, silakan coba lagi.');
      }
    } on PlatformException catch (e) {
      debugPrint('[OtaUpdateService] PlatformException: ${e.code} - ${e.message}');
      onError('Gagal membuka installer: ${e.message}');
    } catch (e) {
      debugPrint('[OtaUpdateService] Error tak terduga: $e');
      onError('Gagal mengunduh pembaruan, silakan coba lagi.');
    }
  }

  static void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  static Future<bool> canInstallPackages() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('canInstallPackages');
      return result ?? true;
    } catch (e) {
      // MissingPluginException kalau native belum di-rebuild, atau error lain — jangan blokir alur update
      debugPrint('[OtaUpdateService] canInstallPackages gagal: $e');
      return true;
    }
  }

  static Future<void> openInstallPermissionSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openInstallPermissionSettings');
    } catch (e) {
      debugPrint('[OtaUpdateService] openInstallPermissionSettings gagal: $e');
    }
  }
}
