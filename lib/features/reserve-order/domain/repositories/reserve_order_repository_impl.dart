import 'package:dartz/dartz.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class ReserveOrderRepositoryImpl implements ReserveOrderRepository {
  final ReserveOrderRemoteDataSource remoteDataSource;

  ReserveOrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<ReserveStatusEntity>>> getReserveStatuses() async {
    try {
      final result = await remoteDataSource.getReserveStatuses();
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, List<CaraBayarEntity>>> getCaraBayar() async {
    try {
      final result = await remoteDataSource.getCaraBayar();
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, List<String>>> getWorkCategory() async {
    try {
      final result = await remoteDataSource.getWorkCategory();
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, List<PaymentTypeEntity>>> getPaymentTypes() async {
    try {
      final result = await remoteDataSource.getPaymentTypes();
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, List<SelectUnitEntity>>> getSelectUnit({
    required int contactId,
    required int townshipId,
  }) async {
    try {
      final result = await remoteDataSource.getSelectUnit(
        contactId: contactId,
        townshipId: townshipId,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, CreateReserveOrderResultEntity>> createReserveOrder(
    CreateReserveOrderParams params,
  ) async {
    try {
      final result = await remoteDataSource.createReserveOrder(params);
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }
}
