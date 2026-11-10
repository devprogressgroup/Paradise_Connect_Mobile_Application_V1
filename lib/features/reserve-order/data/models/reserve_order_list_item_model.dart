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
    super.currentMilestoneLabel,
    super.kasirApproval,
    super.saApproval,
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
      // `current_milestone` = {timeline_reserve_order_id, code, label, date} | null (tahap setelah SP aktif).
      currentMilestoneLabel: json['current_milestone'] is Map
          ? (json['current_milestone'] as Map)['label'] as String?
          : null,
      // `approval` = {kasir: approved|pending|rejected, sa: approved|pending|rejected|null}.
      kasirApproval: json['approval'] is Map
          ? (json['approval'] as Map)['kasir'] as String?
          : null,
      saApproval: json['approval'] is Map
          ? (json['approval'] as Map)['sa'] as String?
          : null,
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
    super.progressOptions,
    super.approvalOptions,
  });

  factory ReserveOrderListResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final filterOptions = json['filter_options'] is Map
        ? json['filter_options'] as Map
        : null;
    return ReserveOrderListResultModel(
      items: data
          .map((e) => ReserveOrderListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? data.length,
      total: json['total'] as int? ?? data.length,
      progressOptions: _options(filterOptions?['progres_akad']),
      approvalOptions: _options(filterOptions?['persetujuan']),
    );
  }

  /// `[{id, name, subtitle?}]` → daftar pilihan; bukan list (tidak dikirim) → null.
  static List<ReserveOrderFilterOptionEntity>? _options(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .where((e) => e['id'] is int && e['name'] is String)
        .map(
          (e) => ReserveOrderFilterOptionEntity(
            id: e['id'] as int,
            name: e['name'] as String,
            subtitle: e['subtitle'] as String?,
          ),
        )
        .toList();
  }
}
