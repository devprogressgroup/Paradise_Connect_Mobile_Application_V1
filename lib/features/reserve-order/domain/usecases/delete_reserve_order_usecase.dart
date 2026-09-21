import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class DeleteReserveOrderUseCase {
  final ReserveOrderRepository repository;

  DeleteReserveOrderUseCase(this.repository);

  Future<Either<String, void>> call(int reserveOrderId) async {
    return await repository.deleteReserveOrder(reserveOrderId);
  }
}
