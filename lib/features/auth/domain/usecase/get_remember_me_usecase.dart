import '../../data/repositories/auth_repository.dart';

class GetRememberMeUseCase {
  final AuthRepository repository;

  GetRememberMeUseCase(this.repository);

  Future<(String, String)?> call() async {
    return await repository.getRememberMe();
  }
}
