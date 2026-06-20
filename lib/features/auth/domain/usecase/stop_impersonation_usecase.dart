import '../../data/repositories/auth_repository.dart';

class StopImpersonationUseCase {
  final AuthRepository repository;

  StopImpersonationUseCase(this.repository);

  /// Mengembalikan token admin asli yang di-stash (keluar dari impersonate).
  Future<void> call() => repository.stopImpersonation();
}
