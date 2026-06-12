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

    _cancelToken = CancelToken();

    try {
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
          if (total > 0) onProgress(received / total);
        },
      );

      onInstalling();

      await _channel.invokeMethod('installApk', {'filePath': savePath});
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      onError('Download gagal: ${e.message}');
    } on PlatformException catch (e) {
      onError('Gagal membuka installer: ${e.message}');
    } catch (e) {
      onError('Error: $e');
    }
  }

  static void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
