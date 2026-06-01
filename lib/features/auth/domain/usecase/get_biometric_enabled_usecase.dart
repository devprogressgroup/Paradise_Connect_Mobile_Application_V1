import '../../data/repositories/auth_repository.dart';

class GetBiometricEnabledUseCase {
  final AuthRepository repository;

  GetBiometricEnabledUseCase(this.repository);

  Future<bool> call() async {
    return await repository.getBiometricEnabled();
  }
}
