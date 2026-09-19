import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetPaymentTypesUseCase {
  final ReserveOrderRepository repository;

  GetPaymentTypesUseCase(this.repository);

  Future<Either<String, List<PaymentTypeEntity>>> call() async {
    return await repository.getPaymentTypes();
  }
}
