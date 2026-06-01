import '../../data/repositories/auth_repository.dart';

class SaveBiometricEnabledUseCase {
  final AuthRepository repository;

  SaveBiometricEnabledUseCase(this.repository);

  Future<void> call(bool value) async {
    return await repository.saveBiometricEnabled(value);
  }
}
