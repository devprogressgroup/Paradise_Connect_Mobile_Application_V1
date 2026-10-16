import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class UpdateReserveOrderQuestionnaireUseCase {
  final ReserveOrderRepository repository;

  UpdateReserveOrderQuestionnaireUseCase(this.repository);

  Future<Either<String, ReserveOrderDetailEntity>> call(
    int reserveOrderId,
    Map<String, String?> answers,
  ) async {
    return await repository.updateQuestionnaire(reserveOrderId, answers);
  }
}
