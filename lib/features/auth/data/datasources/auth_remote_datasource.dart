
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> forgotPassword(String phone);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          "username": username,
          "password": password,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      } else {
        throw Exception("Tidak dapat terhubung ke server");
      }
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final response = await dio.post(
        '/forgot-password',
        data: {
          "whatsapp_number": phone,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      } else {
        throw Exception("Tidak dapat terhubung ke server");
      }
    }
  }
}