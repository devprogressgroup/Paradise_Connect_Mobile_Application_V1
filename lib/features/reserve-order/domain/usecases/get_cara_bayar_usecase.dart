import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetCaraBayarUseCase {
  final ReserveOrderRepository repository;

  GetCaraBayarUseCase(this.repository);

  Future<Either<String, List<CaraBayarEntity>>> call() async {
    return await repository.getCaraBayar();
  }
}
