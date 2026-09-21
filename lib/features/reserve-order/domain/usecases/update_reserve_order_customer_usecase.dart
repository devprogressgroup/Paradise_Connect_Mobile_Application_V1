import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/update_reserve_order_customer_params.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class UpdateReserveOrderCustomerUseCase {
  final ReserveOrderRepository repository;

  UpdateReserveOrderCustomerUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  ) async {
    return await repository.updateReserveOrderCustomer(reserveOrderId, params);
  }
}
