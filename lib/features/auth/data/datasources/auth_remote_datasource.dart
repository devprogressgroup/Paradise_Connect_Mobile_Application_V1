
import 'package:dio/dio.dart';

import '../../domain/entities/reset_password.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> forgotPassword(String phone);
  Future<Map<String, dynamic>> resetPassword(ResetPasswordEntity resetPasswordEntity);
  Future<Map<String, dynamic>> getMe();
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

  @override
  Future<Map<String, dynamic>> resetPassword(ResetPasswordEntity resetPasswordEntity) async {
    try {
      final response = await dio.post(
        '/reset-password',
        data: {
          "user_id": resetPasswordEntity.userId,
          "otp": resetPasswordEntity.otp,
          "password": resetPasswordEntity.password,
          "password_confirmation": resetPasswordEntity.passwordConfirmation,
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
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await dio.get('/me');
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