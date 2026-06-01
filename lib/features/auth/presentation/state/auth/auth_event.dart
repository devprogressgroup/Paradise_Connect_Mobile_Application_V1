
import 'package:progress_group/features/auth/domain/entities/reset_password.dart';

abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  LoginEvent(this.username, this.password, {this.rememberMe = false});
}

class ForgotPasswordEvent extends AuthEvent {
  final String phone;

  ForgotPasswordEvent(this.phone);
}

class CheckRememberMeEvent extends AuthEvent {}

class CheckBiometricEnabledEvent extends AuthEvent {}

class SaveBiometricEnabledEvent extends AuthEvent {
  final bool enabled;
  SaveBiometricEnabledEvent(this.enabled);
}

class SaveCredentialsForBiometricEvent extends AuthEvent {
  final String username;
  final String password;
  SaveCredentialsForBiometricEvent(this.username, this.password);
}

class UpdateProfileEvent extends AuthEvent {
  final String? email;
  final String? phoneNumber;
  final String? password;
  final String? passwordConfirmation;
  final String? photoPath;
  final List<int>? photoBytes;
  final String? photoFilename;

  UpdateProfileEvent({this.email, this.phoneNumber, this.password, this.passwordConfirmation, this.photoPath, this.photoBytes, this.photoFilename});
}

class LogoutEvent extends AuthEvent {}

class ClearRememberMeEvent extends AuthEvent {}

class ResetPasswordEvent extends AuthEvent {
  final ResetPasswordEntity entity;
  ResetPasswordEvent(this.entity);
}