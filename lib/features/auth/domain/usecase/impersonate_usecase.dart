import '../../data/repositories/auth_repository.dart';

class ImpersonateUseCase {
  final AuthRepository repository;

  ImpersonateUseCase(this.repository);

  /// Memulai impersonate user [userId]. Repository menukar token (token target
  /// disimpan, token admin di-stash). Mengembalikan nama user target.
  Future<String> call(int userId) => repository.impersonate(userId);
}
