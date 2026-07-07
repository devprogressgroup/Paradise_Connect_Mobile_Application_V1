import '../../domain/entities/reset_password.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../models/forgot_password_data_model.dart';
import '../models/impersonatable_user_model.dart';
import '../models/permissions_model.dart';

abstract class AuthRepository {
  Future<(UserEntity, String)> login(String username, String password, {bool rememberMe = false});
  Future<(ForgotPasswordDataModel, String)> forgotPassword(String phone);
  Future<String> resetPassword(ResetPasswordEntity entity);
  Future<(String, String)?> getRememberMe();
  Future<void> clearRememberMe();
  Future<void> saveCredentials(String username, String password);
  Future<void> saveBiometricEnabled(bool value);
  Future<bool> getBiometricEnabled();
  Future<String> updateProfile({String? email, String? phoneNumber, String? password, String? passwordConfirmation, String? photoPath, List<int>? photoBytes, String? photoFilename});
  Future<void> logout();
  Future<UserProfileEntity> getProfile();
  Future<PermissionsModel> fetchPermissions();


  Future<List<ImpersonatableUser>> getImpersonatableUsers({String? search});
  Future<String> impersonate(int userId); 
  Future<void> stopImpersonation();
}