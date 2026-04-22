
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

class ClearRememberMeEvent extends AuthEvent {}

class ResetPasswordEvent extends AuthEvent {
  final ResetPasswordEntity entity;
  ResetPasswordEvent(this.entity);
}