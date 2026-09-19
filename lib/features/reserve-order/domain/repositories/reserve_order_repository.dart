import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';

abstract class ReserveOrderRepository {
  Future<Either<String, List<ReserveStatusEntity>>> getReserveStatuses();
}
