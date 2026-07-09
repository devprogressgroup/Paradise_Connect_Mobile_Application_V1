import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';

import '../../../../core/network/base_response.dart';
import '../../../../core/utils/helpers/error_parser.dart';
import '../../domain/entities/reset_password.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/forgot_password_data_model.dart';
import '../models/impersonatable_user_model.dart';
import '../models/login_data_model.dart';
import '../models/permissions_model.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';
import 'auth_repository.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<(UserEntity, String)> login(String username, String password, {bool rememberMe = false}) async {
    final result = await remoteDataSource.login(username, password);

    final response = BaseResponse<LoginDataModel>.fromJson(
      result,
      (data) => LoginDataModel.fromJson(data),
    );

    if (!response.status) {
      if (response.errors != null) {
        throw Exception(parseError(response.errors));
      } else {
        throw Exception(response.message);
      }
    }

    final data = response.data!;
    final entity = UserEntity(
      userId: data.userId,
      accessToken: data.accessToken,
    );

    await localDataSource.saveToken(data.accessToken, persistent: rememberMe);
    await localDataSource.saveAutoLogin(rememberMe);

    if (rememberMe) {
      await localDataSource.saveRememberMe(username, password);
    } else {
      await localDataSource.clearRememberMe();
    }

    return (entity, response.message);
  }

  @override
  Future<(ForgotPasswordDataModel, String)> forgotPassword(String phone) async {
   final result = await remoteDataSource.forgotPassword(phone);

   final response = BaseResponse<ForgotPasswordDataModel>.fromJson(
     result,
     (data) => ForgotPasswordDataModel.fromJson(data),
   );

   if (!response.status) {
     if (response.errors != null) {
       throw Exception(parseError(response.errors));
     } else {
       throw Exception(response.message);
     }
   }

   return (response.data!, response.message);
  }

    
  @override
  Future<String> resetPassword(ResetPasswordEntity entity) async {
    final result = await remoteDataSource.resetPassword(entity);

    final response = BaseResponse<dynamic>.fromJson(
      result,
      (data) => data,
    );

    if (!response.status) {
      throw Exception(
        response.errors != null
            ? parseError(response.errors)
            : response.message,
      );
    }

    return response.message;
  }

  @override
  Future<(String, String)?> getRememberMe() {
    return localDataSource.getRememberMe();
  }

  @override
  Future<void> clearRememberMe() {
    return localDataSource.clearRememberMe();
  }

  @override
  Future<void> saveCredentials(String username, String password) {
    return localDataSource.saveRememberMe(username, password);
  }

  @override
  Future<String> updateProfile({String? email, String? phoneNumber, String? password, String? passwordConfirmation, String? photoPath, List<int>? photoBytes, String? photoFilename}) async {
    final result = await remoteDataSource.updateProfile(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      passwordConfirmation: passwordConfirmation,
      photoPath: photoPath,
      photoBytes: photoBytes,
      photoFilename: photoFilename,
    );

    final response = BaseResponse<dynamic>.fromJson(result, (data) => data);

    if (!response.status) {
      throw Exception(response.errors != null ? parseError(response.errors) : response.message);
    }

    return response.message;
  }

  @override
  Future<void> saveBiometricEnabled(bool value) {
    return localDataSource.saveBiometricEnabled(value);
  }

  @override
  Future<bool> getBiometricEnabled() {
    return localDataSource.getBiometricEnabled();
  }

  @override
  Future<PermissionsModel> fetchPermissions() async {
    final result = await remoteDataSource.getPermissions();
    final response = BaseResponse<PermissionsModel>.fromJson(
      result,
      (data) => PermissionsModel.fromJson(data),
    );
    if (!response.status) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}

    await localDataSource.clearToken();

    await localDataSource.clearImpersonatorToken();
  }

  @override
  Future<UserProfileEntity> getProfile() async {
    final result = await remoteDataSource.getMe();

    final response = BaseResponse<UserProfileModel>.fromJson(
      result,
      (data) => UserProfileModel.fromJson(data),
    );

    if (!response.status) {
      throw Exception(response.message);
    }

    return response.data!;
  }

  @override
  Future<List<ImpersonatableUser>> getImpersonatableUsers({String? search}) async {
    final result = await remoteDataSource.getImpersonatableUsers(search: search);

    final response = BaseResponse<List<ImpersonatableUser>>.fromJson(
      result,
      (data) => (data as List)
          .map((e) => ImpersonatableUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!response.status) {
      throw Exception(response.errors != null ? parseError(response.errors) : response.message);
    }

    return response.data ?? [];
  }

  @override
  Future<String> impersonate(int userId) async {
    final result = await remoteDataSource.impersonate(userId);

    final response = BaseResponse<Map<String, dynamic>>.fromJson(
      result,
      (data) => data as Map<String, dynamic>,
    );

    if (!response.status || response.data == null) {
      throw Exception(response.errors != null ? parseError(response.errors) : response.message);
    }

    final data = response.data!;
    final newToken = data['access_token'] as String;
    final targetName = (data['user']?['full_name'] ?? 'User').toString();

    
    
    final adminToken = await localDataSource.getToken();
    if (adminToken != null && adminToken.isNotEmpty) {
      await localDataSource.saveImpersonatorToken(adminToken);
    }
    await localDataSource.saveToken(newToken, persistent: true);

    return targetName;
  }

  @override
  Future<void> stopImpersonation() async {
    final adminToken = await localDataSource.getImpersonatorToken();
    if (adminToken == null || adminToken.isEmpty) {
      throw Exception('Token admin tidak ditemukan. Silakan login ulang.');
    }
    
    await localDataSource.saveToken(adminToken, persistent: true);
    await localDataSource.clearImpersonatorToken();
  }
}