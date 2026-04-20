
class ResetPasswordEntity {
  final int userId;
  final String otp;
  final String password;
  final String passwordConfirmation;

  ResetPasswordEntity({
    required this.userId,
    required this.otp,
    required this.password,
    required this.passwordConfirmation,
  });
}