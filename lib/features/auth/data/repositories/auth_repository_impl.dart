import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';

import '../../../../core/network/base_response.dart';
import '../../../../core/utils/helpers/error_parser.dart';
import '../../domain/entities/reset_password.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/forgot_password_data_model.dart';
import '../models/login_data_model.dart';
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
  Future<void> logout() async {
    await localDataSource.clearToken();
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
}