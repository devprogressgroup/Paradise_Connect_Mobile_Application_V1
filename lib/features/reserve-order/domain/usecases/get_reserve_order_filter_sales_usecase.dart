import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_filter_sales_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetReserveOrderFilterSalesUseCase {
  final ReserveOrderRepository repository;

  GetReserveOrderFilterSalesUseCase(this.repository);

  Future<Either<String, ReserveOrderFilterSalesEntity>> call() async {
    return await repository.getFilterSales();
  }
}
