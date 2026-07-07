import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/router.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/presentation/state/auth/auth_bloc.dart';
import '../../features/auth/presentation/state/auth/auth_event.dart';
import 'api_constants.dart';
import 'proxy_cipher.dart';
import '../../core/utils/web_debug_util.dart' as web_debug;
import '../../core/utils/helpers/app_time.dart';
import '../../core/utils/widget/device_time_warning_dialog.dart';

class DioClient {
  final AuthLocalDataSource _authLocalDataSource;
  late final Dio _dio;

  static bool _isHandling401 = false;

  static void resetSession() {
    _isHandling401 = false;
  }

  static void _printLong(String text, {int chunkSize = 800}) {
    for (var i = 0; i < text.length; i += chunkSize) {
      // debugPrint(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
    }
  }

  static void _showGlobalSnackbar(String message) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _checkDeviceTimeDrift() {
    if (!AppTime.consumeSuspiciousDriftFlag()) return;
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    showDeviceTimeWarningDialog(context);
  }

  static bool _certWarningShown = false;

  // HTTPS ditolak (sertifikat dianggap invalid) hampir selalu berarti jam
  // perangkat salah (sertifikat server valid tapi tampak "belum berlaku"/
  // "kadaluarsa" di mata device). Ini terjadi SEBELUM ada response sama
  // sekali, jadi AppTime (yang butuh response utk sync) tidak akan sempat
  // mendeteksinya — makanya perlu ditangkap terpisah dari drift check di atas.
  static void _checkCertificateError(DioException e) {
    if (e.type != DioExceptionType.badCertificate || _certWarningShown) return;
    _certWarningShown = true;
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    showDeviceTimeWarningDialog(context, message: certErrorMessage);
  }

  DioClient(this._authLocalDataSource) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          "Accept": "application/json",
        },
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authLocalDataSource.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          final isFileDownload = options.responseType == ResponseType.bytes ||
              options.responseType == ResponseType.stream;
          if (isFileDownload) {
            options.receiveTimeout = const Duration(minutes: 3);
          }
          final skipEncryption = options.extra['skipEncryption'] == true;
          if (!isFileDownload && !skipEncryption) {
            if (kDebugMode) {
              final rawData = options.data;
              if (rawData is FormData) {
                // debugPrint('>>> [REQ BODY] ${options.method} ${options.path}');
                // debugPrint('    fields: ${rawData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');
                // debugPrint('    files : ${rawData.files.map((e) => '${e.key}=${e.value.filename} (${e.value.length}B)').join(', ')}');
              } else if (rawData != null) {
                // debugPrint('>>> [REQ BODY] ${options.method} ${options.path}: $rawData');
              }
            }
            dynamic body;
            if (options.data is FormData) {
              final fd = options.data as FormData;
              final map = <String, dynamic>{};
              for (final f in fd.fields) {
                map[f.key] = f.value;
              }
              for (final f in fd.files) {
                final chunks = await f.value.finalize().toList();
                final bytes = chunks.fold<List<int>>([], (a, b) => a..addAll(b));
                map[f.key] = {
                  '__file': true,
                  'filename': f.value.filename ?? 'file',
                  'data': base64Encode(bytes),
                  'contentType': f.value.contentType?.mimeType ?? 'application/octet-stream',
                };
              }
              body = map;
            } else if (options.data is Map) {
              body = Map<String, dynamic>.from(options.data as Map);
            } else {
              body = options.data;
            }
            final payload = {
              'method': options.method,
              'path': options.path,
              'query': Map<String, dynamic>.from(options.queryParameters),
              'body': body,
              'ts': AppTime.now().millisecondsSinceEpoch,
            };
            if (kDebugMode) {
              _printLong('[REQ DECRYPT] ${payload['method']} ${payload['path']} => ${jsonEncode(payload)}');
            }
            options.method = 'POST';
            options.path = '/px';
            options.queryParameters.clear();
            options.data = {'r': ProxyCipher.encrypt(payload)};
            options.headers['Content-Type'] = 'application/json';
          }

          if (kDebugMode) {
            // debugPrint(">>> [${options.method}] ${options.uri}");
            if (options.data is Map) {
              final r = (options.data as Map)['r']?.toString() ?? '';
              _printLong('[REQ ENCRYPTED] $r');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppTime.syncFromHeader(response.headers.value('date'));
          _checkDeviceTimeDrift();
          final isFileDownload = response.requestOptions.responseType == ResponseType.bytes ||
              response.requestOptions.responseType == ResponseType.stream;
          if (!isFileDownload) {
            response.data = ProxyCipher.decrypt(response.data);
            if (kDebugMode) {
              _printLong('[RES Des ${response.statusCode}] ${response.requestOptions.path} => ${jsonEncode(response.data)}');
            }
            final data = response.data;
            if (data is Map) {
              final status = data['status'];
              final message = data['message']?.toString() ?? '';
              if (status == false && message.toLowerCase().contains('too many')) {
                _showGlobalSnackbar('Terlalu banyak percobaan. Coba beberapa saat lagi.');
              }
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          AppTime.syncFromHeader(e.response?.headers.value('date'));
          _checkDeviceTimeDrift();
          _checkCertificateError(e);
          if (e.response != null) {
            final isFileDownload = e.requestOptions.responseType == ResponseType.bytes ||
                e.requestOptions.responseType == ResponseType.stream;
            if (!isFileDownload) {
              e.response!.data = ProxyCipher.decrypt(e.response!.data);
              if (kDebugMode) {
                _printLong('[RES ERR ${e.response!.statusCode}] ${e.requestOptions.path} => ${jsonEncode(e.response!.data)}');
              }
            }
          }
          if (kDebugMode) debugPrint("DIO ERROR: ${e.message}");

          if (e.response?.statusCode == 429) {
            final message = e.response?.data is Map
                ? (e.response!.data['message']?.toString() ?? 'Terlalu banyak percobaan.')
                : 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
            _showGlobalSnackbar(message);
            return handler.next(e);
          }

          if (e.response?.statusCode == 401 && !_isHandling401) {
            _isHandling401 = true;

            final currentToken = await _authLocalDataSource.getToken();

            // Token sudah null = user logout duluan, jangan tampilkan dialog sesi habis
            if (currentToken == null || currentToken.isEmpty) {
              _isHandling401 = false;
              return handler.next(e);
            }

            // Request yang SUDAH pernah di-retry (ditandai via extra) tidak boleh
            // masuk refresh+retry lagi. Tanpa guard ini: kalau token hasil refresh
            // tetap 401 (misal saat impersonate, token belum sinkron), retry lewat
            // _dio.fetch() masuk lagi ke interceptor ini secara rekursif →
            // refresh+retry tanpa henti → API ditembak berkali-kali sampai tab
            // kehabisan memori & crash/restart ("looping ke login").
            final alreadyRetried = e.requestOptions.extra['_401Retried'] == true;

            if (!alreadyRetried) {
              try {
                  final refreshDio = Dio(BaseOptions(
                    baseUrl: ApiConstants.baseUrl,
                    headers: {
                      "Accept": "application/json",
                      "Authorization": "Bearer $currentToken",
                    },
                  ));

                  final refreshResponse = await refreshDio.post('/refresh');
                  final body = refreshResponse.data as Map<String, dynamic>;

                  if (body['status'] == true) {
                    final newToken = body['data']['access_token'] as String;
                    final persistent = await _authLocalDataSource.isAutoLogin();
                    await _authLocalDataSource.saveToken(newToken, persistent: persistent);
                    _isHandling401 = false;

                    // Retry original request with new token (ditandai, lihat komentar di atas)
                    e.requestOptions.extra['_401Retried'] = true;
                    e.requestOptions.headers["Authorization"] = "Bearer $newToken";
                    final retryResponse = await _dio.fetch(e.requestOptions);
                    return handler.resolve(retryResponse);
                  }
              } catch (refreshErr) {
                debugPrint('[DioClient] Token refresh failed: $refreshErr');
                web_debug.logDebugError('401 token refresh failed: $refreshErr');
              }
            }

            await _authLocalDataSource.clearToken();

            final data401 = e.response?.data;
            final apiMessage = (data401 is Map && data401['message'] != null && data401['message'].toString().isNotEmpty)
                ? data401['message'].toString()
                : 'Sesi Anda telah habis. Silakan login kembali.';

            final context = AppRouter.rootNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              debugPrint('[DioClient] 401 sesi habis — tampilkan dialog. url: ${e.requestOptions.path}');
              web_debug.logDebugError('401 sesi habis (dialog) — ${e.requestOptions.path}: $apiMessage');
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Sesi Berakhir"),
                  content: Text(apiMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // debugPrint('[DioClient] LogoutEvent dipicu dari: dialog Sesi Berakhir (tombol OK)');
                        web_debug.logDebugError('LogoutEvent dipicu dari: dialog Sesi Berakhir (tombol OK)');
                        Navigator.of(dialogContext).pop();
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
              // debugPrint('[DioClient] 401 sesi habis — context null, redirect ke /login. url: ${e.requestOptions.path}');
              web_debug.logDebugError('401 sesi habis (silent redirect /login) — ${e.requestOptions.path}: $apiMessage');
              _isHandling401 = false;
              AppRouter.router.go('/login');
            }
            // Reject dengan marker khusus agar feature layer tidak tampilkan dialog duplikat
            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: 'SESSION_EXPIRED',
              type: DioExceptionType.cancel,
            ));
          }
          return handler.next(e);
        },
      ),
    );

    // if (kDebugMode) {
    //   _dio.interceptors.add(LogInterceptor(
    //     requestBody: true,
    //     responseBody: true,
    //   ));
    // }
  }

  Dio get dio => _dio;
}

