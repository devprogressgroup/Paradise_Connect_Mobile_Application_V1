import '../../data/repositories/auth_repository.dart';

class ClearRememberMeUseCase {
  final AuthRepository repository;

  ClearRememberMeUseCase(this.repository);

  Future<void> call() async {
    return await repository.clearRememberMe();
  }
}
