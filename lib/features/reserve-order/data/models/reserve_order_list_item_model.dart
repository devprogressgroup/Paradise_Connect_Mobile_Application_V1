import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';

class ReserveOrderListItemModel extends ReserveOrderListItemEntity {
  const ReserveOrderListItemModel({
    required super.reserveOrderId,
    required super.customerName,
    super.unitName,
    super.unitSub,
    super.salesName,
    super.amount,
    super.category,
    super.statusLabel,
    super.isRejected,
    super.statusReserveId,
    super.statusReserveName,
    super.dateLabel,
    required super.createdAt,
  });

  factory ReserveOrderListItemModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderListItemModel(
      reserveOrderId: json['reserve_order_id'] as int,
      customerName: json['customer_name'] as String? ?? '-',
      unitName: json['unit_name'] as String?,
      unitSub: json['unit_sub'] as String?,
      salesName: json['sales_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      statusLabel: json['status_label'] as String?,
      isRejected: json['is_rejected'] == true,
      statusReserveId: json['status_reserve_id'] as int?,
      statusReserveName:
          (json['status_reserve_display_name'] as String?)?.isNotEmpty == true
              ? json['status_reserve_display_name'] as String
              : json['status_reserve_name'] as String?,
      dateLabel: json['date_label'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ReserveOrderListResultModel extends ReserveOrderListResultEntity {
  const ReserveOrderListResultModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.perPage,
    required super.total,
  });

  factory ReserveOrderListResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    return ReserveOrderListResultModel(
      items: data
          .map((e) => ReserveOrderListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? data.length,
      total: json['total'] as int? ?? data.length,
    );
  }
}
