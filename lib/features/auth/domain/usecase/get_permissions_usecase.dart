import '../../data/models/permissions_model.dart';
import '../../data/repositories/auth_repository.dart';

class GetPermissionsUseCase {
  final AuthRepository repository;

  GetPermissionsUseCase(this.repository);

  Future<PermissionsModel> call() => repository.fetchPermissions();
}
