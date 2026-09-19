import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';

class CreateReserveOrderResultModel extends CreateReserveOrderResultEntity {
  const CreateReserveOrderResultModel({
    required super.customerId,
    required super.custName,
    required super.orders,
  });

  factory CreateReserveOrderResultModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? const {};
    final orders = (json['reserve_orders'] as List<dynamic>? ?? const [])
        .map((e) => CreateReserveOrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CreateReserveOrderResultModel(
      customerId: customer['customer_id'] as int,
      custName: customer['cust_name'] as String? ?? '',
      orders: orders,
    );
  }
}

class CreateReserveOrderItemModel extends CreateReserveOrderItemEntity {
  const CreateReserveOrderItemModel({
    required super.reserveOrderId,
    super.propertyName,
    super.statusReserveId,
    required super.reserveOrderTtsId,
    required super.ttsNumber,
    required super.ttsAmountRp,
  });

  factory CreateReserveOrderItemModel.fromJson(Map<String, dynamic> json) {
    final tts = json['tts'] as Map<String, dynamic>? ?? const {};
    return CreateReserveOrderItemModel(
      reserveOrderId: json['reserve_order_id'] as int,
      propertyName: json['property_name'] as String?,
      statusReserveId: json['status_reserve_id'] as int?,
      reserveOrderTtsId: tts['reserve_order_tts_id'] as int,
      ttsNumber: tts['tts_number'] as String? ?? '',
      ttsAmountRp: (tts['tts_amount_rp'] as num?)?.toDouble() ?? 0,
    );
  }
}
