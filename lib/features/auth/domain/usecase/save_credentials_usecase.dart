import '../../data/repositories/auth_repository.dart';

class SaveCredentialsUseCase {
  final AuthRepository repository;

  SaveCredentialsUseCase(this.repository);

  Future<void> call(String username, String password) async {
    return await repository.saveCredentials(username, password);
  }
}
