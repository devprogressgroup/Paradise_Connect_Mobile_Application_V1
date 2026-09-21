import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetReserveOrderDetailUseCase {
  final ReserveOrderRepository repository;

  GetReserveOrderDetailUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
  ) async {
    return await repository.getReserveOrderDetail(reserveOrderId);
  }
}
