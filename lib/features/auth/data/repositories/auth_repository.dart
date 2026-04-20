import '../../domain/entities/reset_password.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../models/forgot_password_data_model.dart';

abstract class AuthRepository {
  Future<(UserEntity, String)> login(String username, String password, {bool rememberMe = false});
  Future<(ForgotPasswordDataModel, String)> forgotPassword(String phone);
  Future<String> resetPassword(ResetPasswordEntity entity);
  Future<(String, String)?> getRememberMe();
  Future<void> clearRememberMe();
  Future<void> logout();
  Future<UserProfileEntity> getProfile();
}