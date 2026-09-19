import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetSelectUnitUseCase {
  final ReserveOrderRepository repository;

  GetSelectUnitUseCase(this.repository);

  Future<Either<String, List<SelectUnitEntity>>> call({
    required int contactId,
    required int townshipId,
  }) async {
    return await repository.getSelectUnit(
      contactId: contactId,
      townshipId: townshipId,
    );
  }
}
