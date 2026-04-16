import '../../data/repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<(UserEntity, String)> call(String username, String password, {bool rememberMe = false}) async {
    return await repository.login(username, password, rememberMe: rememberMe);
  }
}