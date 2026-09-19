import 'package:flutter/material.dart';

/// Satu baris di halaman List Reserve Order.
class ReserveOrderListItem {
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
}
