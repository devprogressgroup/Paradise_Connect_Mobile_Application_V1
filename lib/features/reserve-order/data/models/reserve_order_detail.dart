import 'package:flutter/material.dart';

import 'reserve_order_customer_data.dart';

/// Emoji ikon per jenis dokumen (tab Attachment di Detail) — persis `DOC_ICON` di prototype
/// `reserve-order-prototype (1).html`.
const Map<String, String> reserveOrderDocIcons = {
  'Formulir Aplikasi': '📝',
  'KTP Pemohon & Pasangan': '🪪',
  'Surat Nikah/Cerai': '💍',
  'Kartu Keluarga': '👨‍👩‍👧',
  'Rekening Koran 3 Bulan Terakhir': '🏦',
  'NPWP Pribadi': '📄',
  'Slip Gaji / Surat Keterangan Penghasilan & Jabatan': '💰',
  'Ijin Praktek Profesi': '⚕️',
  'Neraca Laba Rugi / Info Keuangan Terakhir': '📊',
  'Akte Pendirian Perusahaan & Ijin Usaha': '🏢',
};

enum ReserveOrderStepStatus { done, active, todo }

class ReserveOrderTimelineNote {
  final String who;
  final String text;
  const ReserveOrderTimelineNote(this.who, this.text);
}

class ReserveOrderTimelineStep {
  final String label;
  final String? sub;
  final Color? subColor;
  final ReserveOrderStepStatus status;
  final List<ReserveOrderTimelineNote> notes;

  const ReserveOrderTimelineStep({
    required this.label,
    this.sub,
    this.subColor,
    required this.status,
    this.notes = const [],
  });
}

class ReserveOrderChatMessage {
  final String who;
  final String role;
  final String time;
  final String text;
  final Color color;

  ReserveOrderChatMessage({
    required this.who,
    required this.role,
    required this.time,
    required this.text,
    required this.color,
  });
}

/// Satu Reserve Order lengkap dengan detail — dipakai `ReserveOrderDetailPage`.
class ReserveOrderDetail {
  String customerName;
  final String avatarInitials;
  String phone;
  final String unitName;
  final String unitSub;
  final int? price;
  final bool canTopup;
  final bool rejected;
  final String? rejectStage;
  final String? rejectReason;
  final bool rejectFixIsCustomerData;
  final List<ReserveOrderTimelineStep> timeline;
  ReserveOrderCustomerData customer;
  final List<String> requiredDocs;
  final Map<String, bool> docsUploaded;
  final List<ReserveOrderChatMessage> notes;
  final int totalPaidSoFar;

  ReserveOrderDetail({
    required this.customerName,
    required this.avatarInitials,
    required this.phone,
    required this.unitName,
    required this.unitSub,
    this.price,
    required this.canTopup,
    required this.rejected,
    this.rejectStage,
    this.rejectReason,
    this.rejectFixIsCustomerData = false,
    required this.timeline,
    required this.customer,
    required this.requiredDocs,
    required this.docsUploaded,
    required this.notes,
    this.totalPaidSoFar = 2000000,
  });
}
