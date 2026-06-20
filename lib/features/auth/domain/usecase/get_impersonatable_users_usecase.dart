import '../../data/models/impersonatable_user_model.dart';
import '../../data/repositories/auth_repository.dart';

class GetImpersonatableUsersUseCase {
  final AuthRepository repository;

  GetImpersonatableUsersUseCase(this.repository);

  Future<List<ImpersonatableUser>> call({String? search}) =>
      repository.getImpersonatableUsers(search: search);
}
