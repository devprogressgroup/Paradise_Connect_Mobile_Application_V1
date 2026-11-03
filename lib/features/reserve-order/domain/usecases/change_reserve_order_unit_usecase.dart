import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/change_reserve_order_unit_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class ChangeReserveOrderUnitUseCase {
  final ReserveOrderRepository repository;

  ChangeReserveOrderUnitUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
    ChangeReserveOrderUnitParams params,
  ) async {
    return await repository.changeReserveOrderUnit(reserveOrderId, params);
  }
}
