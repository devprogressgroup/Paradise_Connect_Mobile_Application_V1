
import 'package:dio/dio.dart';

import '../../domain/entities/reset_password.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> forgotPassword(String phone);
  Future<Map<String, dynamic>> resetPassword(ResetPasswordEntity resetPasswordEntity);
  Future<Map<String, dynamic>> getMe();
  Future<Map<String, dynamic>> updateProfile({String? email, String? phoneNumber, String? password, String? passwordConfirmation});
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

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? phoneNumber,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null && email.isNotEmpty) data['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) data['phone_number'] = phoneNumber;
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
        data['password_confirmation'] = passwordConfirmation ?? password;
      }

      final response = await dio.put('/me', data: data);
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