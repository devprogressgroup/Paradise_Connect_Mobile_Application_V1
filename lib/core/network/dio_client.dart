import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/router.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/presentation/state/auth/auth_bloc.dart';
import '../../features/auth/presentation/state/auth/auth_event.dart';
import 'api_constants.dart';

class DioClient {
  final AuthLocalDataSource _authLocalDataSource;
  late final Dio _dio;

  static bool _isHandling401 = false;

  DioClient(this._authLocalDataSource) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 130),
        receiveTimeout: const Duration(seconds: 130),
        sendTimeout: const Duration(seconds: 130),
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
          print(">>> [${options.method}] ${options.uri}");
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print("DIO ERROR: ${e.message}");

          if (e.response?.statusCode == 401 && !_isHandling401) {
            _isHandling401 = true;

            final currentToken = await _authLocalDataSource.getToken();
            if (currentToken != null && currentToken.isNotEmpty) {
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
            }

            await _authLocalDataSource.clearToken();

            final context = AppRouter.rootNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Sesi Berakhir"),
                  content: const Text("Sesi Anda telah habis. Silakan login kembali."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _isHandling401 = false;
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
          }
          return handler.next(e);
        },
      ),
    );

    // Optional: Add LogInterceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get dio => _dio;
}

