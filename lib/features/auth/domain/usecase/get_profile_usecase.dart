import '../../data/repositories/auth_repository.dart';
import '../entities/user_profile.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserProfileEntity> call() {
    return repository.getProfile();
  }
}
