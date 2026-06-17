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

class DioClient {
  final AuthLocalDataSource _authLocalDataSource;
  late final Dio _dio;

  static bool _isHandling401 = false;

  static void resetSession() {
    _isHandling401 = false;
  }

  static void _printLong(String text, {int chunkSize = 800}) {
    for (var i = 0; i < text.length; i += chunkSize) {
      debugPrint(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
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
          if (!isFileDownload) {
            if (kDebugMode) {
              final rawData = options.data;
              if (rawData is FormData) {
                debugPrint('>>> [REQ BODY] ${options.method} ${options.path}');
                debugPrint('    fields: ${rawData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');
                debugPrint('    files : ${rawData.files.map((e) => '${e.key}=${e.value.filename} (${e.value.length}B)').join(', ')}');
              } else if (rawData != null) {
                debugPrint('>>> [REQ BODY] ${options.method} ${options.path}: $rawData');
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
              'ts': DateTime.now().millisecondsSinceEpoch,
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
            debugPrint(">>> [${options.method}] ${options.uri}");
            if (options.data is Map) {
              final r = (options.data as Map)['r']?.toString() ?? '';
              _printLong('[REQ ENCRYPTED] $r');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
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
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response != null) {
            e.response!.data = ProxyCipher.decrypt(e.response!.data);
            if (kDebugMode) {
              _printLong('[RES ERR ${e.response!.statusCode}] ${e.requestOptions.path} => ${jsonEncode(e.response!.data)}');
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

                  // Retry original request with new token
                  e.requestOptions.headers["Authorization"] = "Bearer $newToken";
                  final retryResponse = await _dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
            } catch (_) {
              // Refresh failed — fall through to logout
            }

            await _authLocalDataSource.clearToken();

            final data401 = e.response?.data;
            final apiMessage = (data401 is Map && data401['message'] != null && data401['message'].toString().isNotEmpty)
                ? data401['message'].toString()
                : 'Sesi Anda telah habis. Silakan login kembali.';

            final context = AppRouter.rootNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Sesi Berakhir"),
                  content: Text(apiMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
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

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Dio get dio => _dio;
}

