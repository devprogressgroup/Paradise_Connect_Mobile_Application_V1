import '../../data/repositories/auth_repository.dart';

class StopImpersonationUseCase {
  final AuthRepository repository;

  StopImpersonationUseCase(this.repository);

 
  Future<void> call() => repository.stopImpersonation();
}
