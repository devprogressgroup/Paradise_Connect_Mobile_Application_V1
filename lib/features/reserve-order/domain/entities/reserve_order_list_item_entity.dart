import 'package:equatable/equatable.dart';

/// Satu baris hasil `GET /reserve-order/list` (`ReserveOrderService::getList`).
class ReserveOrderListItemEntity extends Equatable {
  final int reserveOrderId;
  final String customerName;
  final String? unitName;
  final String? unitSub;
  final String? salesName;
  final double amount;
  final String? category;
  final String? statusLabel;
  final bool isRejected;
  final int? statusReserveId;
  final String? statusReserveName;
  final String? dateLabel;
  final DateTime createdAt;

  const ReserveOrderListItemEntity({
    required this.reserveOrderId,
    required this.customerName,
    this.unitName,
    this.unitSub,
    this.salesName,
    this.amount = 0,
    this.category,
    this.statusLabel,
    this.isRejected = false,
    this.statusReserveId,
    this.statusReserveName,
    this.dateLabel,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    reserveOrderId,
    customerName,
    unitName,
    unitSub,
    salesName,
    amount,
    category,
    statusLabel,
    isRejected,
    statusReserveId,
    statusReserveName,
    dateLabel,
    createdAt,
  ];
}

/// Wrapper paginasi hasil `GET /reserve-order/list`.
class ReserveOrderListResultEntity extends Equatable {
  final List<ReserveOrderListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const ReserveOrderListResultEntity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;

  @override
  List<Object?> get props => [items, currentPage, lastPage, perPage, total];
}
