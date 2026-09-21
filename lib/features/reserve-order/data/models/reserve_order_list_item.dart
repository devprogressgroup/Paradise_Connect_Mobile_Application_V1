import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';

/// Satu baris di halaman List Reserve Order.
class ReserveOrderListItem {
  final int reserveOrderId;
  final String customerName;
  final String status;
  final Color statusColor;
  final String unitName;
  final String unitSub;
  final String salesName;
  final int amount;
  final String category;
  final String dateLabel;
  final DateTime createdAt;

  const ReserveOrderListItem({
    required this.reserveOrderId,
    required this.customerName,
    required this.status,
    required this.statusColor,
    required this.unitName,
    required this.unitSub,
    required this.salesName,
    required this.amount,
    required this.category,
    required this.dateLabel,
    required this.createdAt,
  });

  factory ReserveOrderListItem.fromEntity(ReserveOrderListItemEntity e) {
    return ReserveOrderListItem(
      reserveOrderId: e.reserveOrderId,
      customerName: e.customerName,
      status: e.isRejected
          ? 'Ditolak'
          : (e.statusReserveName ?? e.statusLabel ?? '-'),
      statusColor: reserveOrderStatusColor(
        isRejected: e.isRejected,
        statusReserveId: e.statusReserveId,
      ),
      unitName: e.unitName ?? '-',
      unitSub: e.unitSub ?? '',
      salesName: e.salesName ?? '-',
      amount: e.amount.round(),
      category: e.category ?? '-',
      dateLabel: e.dateLabel ?? '-',
      createdAt: e.createdAt,
    );
  }
}

/// Warna badge status Reserve Order — dipetakan langsung dari `status_reserve_id`
/// (`paradisecoid_pd_common.m_reserve_status`), bukan dari validasi tanggal timeline.
/// ID: 1=RBB, 2=Reserve, 4=Reserve Batal, 5=Waitinglist, 6=SP, 7=RBA, 8=SP Batal.
Color reserveOrderStatusColor({
  required bool isRejected,
  int? statusReserveId,
}) {
  if (isRejected) return const Color(redColor);

  switch (statusReserveId) {
    case 1: // RBB
    case 7: // RBA
      return const Color(rbaColor);
    case 6: // SP
      return const Color(spColor);
    case 5: // Waitinglist
      return const Color(infoColor);
    case 4: // Reserve Batal
    case 8: // SP Batal
      return const Color(grey4Color);
    case 2: // Reserve
    default:
      return const Color(warningColor);
  }
}
