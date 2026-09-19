import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetReserveStatusesUseCase {
  final ReserveOrderRepository repository;

  GetReserveStatusesUseCase(this.repository);

  Future<Either<String, List<ReserveStatusEntity>>> call() async {
    return await repository.getReserveStatuses();
  }
}
