import 'package:dio/dio.dart';
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
        onError: (DioException e, handler) {
          // Log errors or handle common status codes here
          print("DIO ERROR: ${e.message}");
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


