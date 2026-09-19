import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class CreateReserveOrderUseCase {
  final ReserveOrderRepository repository;

  CreateReserveOrderUseCase(this.repository);

  Future<Either<String, CreateReserveOrderResultEntity>> call(
    CreateReserveOrderParams params,
  ) async {
    return await repository.createReserveOrder(params);
  }
}
