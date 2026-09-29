import 'dart:typed_data';

import 'package:dartz/dartz.dart';
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
    int page,
    int perPage,
  });
  Future<Either<String, ReserveOrderDetailEntity>> getReserveOrderDetail(
    int reserveOrderId,
  );
  Future<Either<String, ReserveOrderDetailEntity>> updateReserveOrderCustomer(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  );
  Future<Either<String, ReserveOrderDetailEntity>> topupReserveOrder(
    int reserveOrderId,
    TopupReserveOrderParams params,
  );
  Future<Either<String, ReserveOrderDetailEntity>> sendReserveOrderMessage(
    int reserveOrderId,
    String message,
  );
  Future<Either<String, ReserveOrderDetailEntity>> editReserveOrder(
    int reserveOrderId,
    EditReserveOrderParams params,
  );
  Future<Either<String, void>> deleteReserveOrder(int reserveOrderId);
  Future<Either<String, Map<String, dynamic>>> ocrKtp(
    Uint8List imageBytes, {
    String? filename,
  });
  Future<Either<String, Map<String, dynamic>>> checkKtp(
    String custKtp, {
    String? custName,
    int? contactId,
  });
}
