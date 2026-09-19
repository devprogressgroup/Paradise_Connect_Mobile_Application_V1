import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetWorkCategoryUseCase {
  final ReserveOrderRepository repository;

  GetWorkCategoryUseCase(this.repository);

  Future<Either<String, List<String>>> call() async {
    return await repository.getWorkCategory();
  }
}
