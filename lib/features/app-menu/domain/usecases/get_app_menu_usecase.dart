import 'package:dartz/dartz.dart';
import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';
import 'package:progress_group/features/app-menu/domain/repositories/app_menu_repository.dart';

class GetAppMenuUseCase {
  final AppMenuRepository repository;

  GetAppMenuUseCase(this.repository);

  Future<Either<String, AppMenuEntity>> call() {
    return repository.fetchAppMenu();
  }
}
