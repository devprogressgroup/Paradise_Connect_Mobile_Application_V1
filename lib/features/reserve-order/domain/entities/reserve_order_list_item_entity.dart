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

  /// Nama milestone terakhir yg aktif (tahap setelah SP, mis. "Siap Akad") dari `current_milestone.label`;
  /// null = tahap sekarang masih Leads s/d SP. Badge di bawah status di list.
  final String? currentMilestoneLabel;

  /// Status approval dari server (`approval.kasir` / `approval.sa`): `approved` / `pending` / `rejected`.
  /// [saApproval] null selama Kasir belum menyetujui (SA baru memproses setelah Kasir).
  final String? kasirApproval;
  final String? saApproval;
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
    this.currentMilestoneLabel,
    this.kasirApproval,
    this.saApproval,
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
    currentMilestoneLabel,
    kasirApproval,
    saApproval,
    createdAt,
  ];
}

/// Satu pilihan filter yang datanya dari server (`filter_options` di response list) — ditampilkan apa adanya
/// di sheet Filter. [subtitle] = keterangan kecil di bawah nama, null = tanpa keterangan.
class ReserveOrderFilterOptionEntity extends Equatable {
  final int id;
  final String name;
  final String? subtitle;

  const ReserveOrderFilterOptionEntity({
    required this.id,
    required this.name,
    this.subtitle,
  });

  @override
  List<Object?> get props => [id, name, subtitle];
}

/// Wrapper paginasi hasil `GET /reserve-order/list`.
class ReserveOrderListResultEntity extends Equatable {
  final List<ReserveOrderListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  /// Pilihan filter "Progres Akad" (`filter_options.progres_akad`: tahap setelah SP dari master) &
  /// "Persetujuan" (`filter_options.persetujuan`). Null = response tidak membawanya (hanya dikirim di halaman 1).
  final List<ReserveOrderFilterOptionEntity>? progressOptions;
  final List<ReserveOrderFilterOptionEntity>? approvalOptions;

  const ReserveOrderListResultEntity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.progressOptions,
    this.approvalOptions,
  });

  bool get hasNextPage => currentPage < lastPage;

  @override
  List<Object?> get props => [
    items,
    currentPage,
    lastPage,
    perPage,
    total,
    progressOptions,
    approvalOptions,
  ];
}
