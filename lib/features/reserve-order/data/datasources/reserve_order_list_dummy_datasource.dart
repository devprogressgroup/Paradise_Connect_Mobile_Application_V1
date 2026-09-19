import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

import '../models/reserve_order_list_item.dart';

/// Sumber data halaman List Reserve Order — masih dummy (belum ada API reserve-order di branch
/// ini). Susunan & isinya mengikuti `orders` seed di `reserve-order-prototype (1).html` supaya
/// konsisten dengan mockup desain yang sudah disetujui.
class ReserveOrderListDummyDataSource {
  const ReserveOrderListDummyDataSource();

  List<ReserveOrderListItem> getAll() {
    final now = DateTime.now();
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    return [
      ReserveOrderListItem(
        customerName: 'Reyhan Pradipta',
        status: 'Ditolak',
        statusColor: const Color(redColor),
        unitName: 'Blok E1 No. 22',
        unitSub: 'PAR2 Ecoscape',
        salesName: 'Dian A.',
        amount: 400000000,
        category: 'Profesional',
        dateLabel: 'Diajukan 05 Sep',
        createdAt: daysAgo(1),
      ),
      ReserveOrderListItem(
        customerName: 'Luthfi Fajri',
        status: 'Diproses',
        statusColor: const Color(warningColor),
        unitName: 'Blok E1 No. 19',
        unitSub: 'PAR2 · Ecoscape',
        salesName: 'Dian A.',
        amount: 3000000,
        category: 'Wiraswasta',
        dateLabel: 'Reserve: 05 Sep',
        createdAt: daysAgo(2),
      ),
      ReserveOrderListItem(
        customerName: 'Farah Amelia',
        status: 'Ditolak',
        statusColor: const Color(redColor),
        unitName: 'Blok D2 No. 09',
        unitSub: 'PAR2 · Delano',
        salesName: 'Dian A.',
        amount: 20000000,
        category: 'Pegawai',
        dateLabel: 'SP: 10 Sep',
        createdAt: daysAgo(3),
      ),
      ReserveOrderListItem(
        customerName: 'Salsabila Octariani',
        status: 'RBA',
        statusColor: const Color(rbaColor),
        unitName: 'Blok BC7 No. 28',
        unitSub: 'PAR2 · Arwood',
        salesName: 'Dian A.',
        amount: 20000000,
        category: 'Pegawai',
        dateLabel: 'R/BR: 28 Aug',
        createdAt: daysAgo(5),
      ),
      ReserveOrderListItem(
        customerName: 'Remira Danisk',
        status: 'SP',
        statusColor: const Color(spColor),
        unitName: 'Blok BC6 No. 17',
        unitSub: 'PAR2 · Delano',
        salesName: 'Dian A.',
        amount: 35000000,
        category: 'Profesional',
        dateLabel: 'SP: 02 Sep',
        createdAt: daysAgo(10),
      ),
      ReserveOrderListItem(
        customerName: 'Marcell Yudhistira',
        status: 'Proses Bank',
        statusColor: const Color(infoColor),
        unitName: 'OT Non-Office',
        unitSub: 'Bumi Sadayana BSD',
        salesName: 'Dian A.',
        amount: 20000000,
        category: 'Pegawai',
        dateLabel: 'SP: 22 Aug',
        createdAt: daysAgo(20),
      ),
      ReserveOrderListItem(
        customerName: 'Ikram Wiksa',
        status: 'Akad/PPJB',
        statusColor: const Color(successColor),
        unitName: 'Blok BC6 No. 12',
        unitSub: 'PAR2 · Delano',
        salesName: 'Dian A.',
        amount: 15000000,
        category: 'Wiraswasta',
        dateLabel: 'Akad/PPJB: 12 Aug',
        createdAt: daysAgo(40),
      ),
    ];
  }
}
