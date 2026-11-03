import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetCustomerOptionsUseCase {
  final ReserveOrderRepository repository;

  GetCustomerOptionsUseCase(this.repository);

  Future<Either<String, CustomerOptionsEntity>> call() async {
    return await repository.getCustomerOptions();
  }
}
