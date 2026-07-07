import '../../data/repositories/auth_repository.dart';

class ImpersonateUseCase {
  final AuthRepository repository;

  ImpersonateUseCase(this.repository);

 
 
  Future<String> call(int userId) => repository.impersonate(userId);
}
