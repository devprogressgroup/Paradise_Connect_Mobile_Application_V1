import '../../data/repositories/auth_repository.dart';
import '../entities/reset_password.dart';

class ResetPasswordUsecase {
  final AuthRepository repository;

  ResetPasswordUsecase(this.repository);

  Future<String> call(ResetPasswordEntity entity) async {
    return await repository.resetPassword(entity);
  }
}