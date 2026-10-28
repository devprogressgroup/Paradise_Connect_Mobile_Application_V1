import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/resubmit_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class ResubmitReserveOrderUseCase {
  final ReserveOrderRepository repository;

  ResubmitReserveOrderUseCase(this.repository);

  Future<Either<String, ({ReserveOrderDetailEntity detail, String? message})>>
  call(int reserveOrderId, ResubmitReserveOrderParams params) async {
    return await repository.resubmitReserveOrder(reserveOrderId, params);
  }
}
