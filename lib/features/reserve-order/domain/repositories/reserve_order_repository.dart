import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';

abstract class ReserveOrderRepository {
  Future<Either<String, List<ReserveStatusEntity>>> getReserveStatuses();
  Future<Either<String, List<CaraBayarEntity>>> getCaraBayar();
  Future<Either<String, List<String>>> getWorkCategory();
  Future<Either<String, List<PaymentTypeEntity>>> getPaymentTypes();
  Future<Either<String, List<SelectUnitEntity>>> getSelectUnit({
    required int contactId,
    required int townshipId,
  });
  Future<Either<String, CreateReserveOrderResultEntity>> createReserveOrder(
    CreateReserveOrderParams params,
  );
}
