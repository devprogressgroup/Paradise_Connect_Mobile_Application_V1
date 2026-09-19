import 'package:dartz/dartz.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class ReserveOrderRepositoryImpl implements ReserveOrderRepository {
  final ReserveOrderRemoteDataSource remoteDataSource;

  ReserveOrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<ReserveStatusEntity>>> getReserveStatuses() async {
    try {
      final result = await remoteDataSource.getReserveStatuses();
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }
}
