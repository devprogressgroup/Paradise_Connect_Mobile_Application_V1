import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import 'api_constants.dart';

class DioClient {
  final AuthLocalDataSource _authLocalDataSource;
  late final Dio _dio;

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
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Log errors or handle common status codes here
          print("DIO ERROR: ${e.message}");

          if (e.response?.statusCode == 401) {
            await _authLocalDataSource.clearToken();
            
            final context = AppRouter.rootNavigatorKey.currentContext;
            if (context != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("Sesi Berakhir"),
                  content: const Text("Sesi Anda telah habis. Silakan login kembali."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        AppRouter.router.go('/login');
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
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


