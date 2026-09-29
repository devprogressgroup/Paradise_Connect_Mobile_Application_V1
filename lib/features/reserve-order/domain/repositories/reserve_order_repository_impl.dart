import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/edit_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/update_reserve_order_customer_params.dart';
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

  @override
  Future<Either<String, ReserveOrderListResultEntity>> getReserveOrderList({
    String? search,
    List<int>? statusReserveIds,
    bool? rejected,
    String? sort,
    List<int>? salesChannelIds,
    List<int>? channelDetailIds,
    List<int>? ownerIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? generalManagerIds,
    List<int>? salesTeamIds,
    String? project,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final result = await remoteDataSource.getReserveOrderList(
        search: search,
        statusReserveIds: statusReserveIds,
        rejected: rejected,
        sort: sort,
        salesChannelIds: salesChannelIds,
        channelDetailIds: channelDetailIds,
        ownerIds: ownerIds,
        salesExecutiveIds: salesExecutiveIds,
        salesSupervisorIds: salesSupervisorIds,
        salesManagerIds: salesManagerIds,
        generalManagerIds: generalManagerIds,
        salesTeamIds: salesTeamIds,
        project: project,
        page: page,
        perPage: perPage,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, ReserveOrderDetailEntity>> getReserveOrderDetail(
    int reserveOrderId,
  ) async {
    try {
      final result = await remoteDataSource.getReserveOrderDetail(
        reserveOrderId,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, ReserveOrderDetailEntity>> updateReserveOrderCustomer(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  ) async {
    try {
      final result = await remoteDataSource.updateReserveOrderCustomer(
        reserveOrderId,
        params,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, ReserveOrderDetailEntity>> topupReserveOrder(
    int reserveOrderId,
    TopupReserveOrderParams params,
  ) async {
    try {
      final result = await remoteDataSource.topupReserveOrder(
        reserveOrderId,
        params,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, ReserveOrderDetailEntity>> sendReserveOrderMessage(
    int reserveOrderId,
    String message,
  ) async {
    try {
      final result = await remoteDataSource.sendReserveOrderMessage(
        reserveOrderId,
        message,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, ReserveOrderDetailEntity>> editReserveOrder(
    int reserveOrderId,
    EditReserveOrderParams params,
  ) async {
    try {
      final result = await remoteDataSource.editReserveOrder(
        reserveOrderId,
        params,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, void>> deleteReserveOrder(int reserveOrderId) async {
    try {
      await remoteDataSource.deleteReserveOrder(reserveOrderId);
      return const Right(null);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> ocrKtp(
    Uint8List imageBytes, {
    String? filename,
  }) async {
    try {
      final result = await remoteDataSource.ocrKtp(
        imageBytes,
        filename: filename,
      );
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> checkKtp(
    String custKtp, {
    String? custName,
    int? contactId,
  }) async {
    try {
      final result = await remoteDataSource.checkKtp(custKtp, custName: custName, contactId: contactId);
      return Right(result);
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }
}
