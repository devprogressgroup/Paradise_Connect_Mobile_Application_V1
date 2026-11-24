import 'package:dartz/dartz.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/app-menu/data/datasources/app_menu_remote_datasource.dart';
import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';

abstract class AppMenuRepository {
  /// Ambil menu dari server.
  Future<Either<String, AppMenuEntity>> fetchAppMenu();
}

class AppMenuRepositoryImpl implements AppMenuRepository {
  final AppMenuRemoteDataSource remoteDataSource;

  AppMenuRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, AppMenuEntity>> fetchAppMenu() async {
    try {
      return Right(await remoteDataSource.getAppMenu());
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }
}
