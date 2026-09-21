import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class TopupReserveOrderUseCase {
  final ReserveOrderRepository repository;

  TopupReserveOrderUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
    TopupReserveOrderParams params,
  ) async {
    return await repository.topupReserveOrder(reserveOrderId, params);
  }
}
