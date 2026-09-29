import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';

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
  final bool isMe;
  final String time;
  final String text;
  final Color color;

  ReserveOrderChatMessage({
    required this.who,
    this.role = '',
    this.isMe = false,
    required this.time,
    required this.text,
    required this.color,
  });
}

/// Satu Reserve Order lengkap dengan detail — dipakai `ReserveOrderDetailPage`.
class ReserveOrderDetail {
  final int reserveOrderId;

  /// contact_id (m_contacts) pemilik order ini — null kalau reserve order lama belum tercatat
  /// contact_id-nya; kalau null, tombol upload dokumen di tab Attachment dinonaktifkan.
  final int? contactId;
  String customerName;
  final String avatarInitials;
  String phone;
  final String unitName;
  final String unitSub;

  /// `product_name`, `project_name` (cluster), `township_name` — ditampilkan di header detail.
  final String? productName;
  final String? projectName;
  final String? townshipName;
  final int? price;
  final bool canTopup;

  /// `can_edit` / `can_delete` dari backend (scope Own/Team/Any) — atur tampil tombol aksi.
  final bool canEdit;
  final bool canDelete;
  final bool rejected;
  final String? rejectStage;
  final String? rejectReason;
  final bool rejectFixIsCustomerData;
  final List<ReserveOrderTimelineStep> timeline;
  ReserveOrderCustomerData customer;
  final List<String> requiredDocs;
  final Map<String, bool> docsUploaded;

  /// `attachment_type_id` (m_attachment_type) per nama dokumen di [requiredDocs] — dipakai saat
  /// upload lewat `POST /contacts/{contact_id}/attachments`.
  final Map<String, int> docAttachmentTypeIds;

  /// SEMUA attachment per nama dokumen di [requiredDocs], terbaru di depan (termasuk file TTS/
  /// bukti bayar yang punya `reserve_order_tts_id`) — 1 jenis dokumen bisa berisi beberapa file,
  /// masing2 punya status verifikasi sendiri. Dipakai buat lihat file & "Upload Ulang"
  /// (`PATCH /contacts/{contact_id}/attachments/{id}`, `reserve_order_tts_id` file lama ikut dikirim).
  final Map<String, List<ReserveOrderAttachmentEntity>> docAttachments;
  final List<ReserveOrderChatMessage> notes;
  final int totalPaidSoFar;

  /// Nilai APA ADANYA field yang bisa diedit lewat "Edit Reserve Order" (`POST
  /// /reserve-order/edit/{id}`) — dipakai buat prefill form-nya.
  final String? reserveNote;
  final int? caraBayarId;
  final String? caraBayarName;

  ReserveOrderDetail({
    required this.reserveOrderId,
    this.contactId,
    required this.customerName,
    required this.avatarInitials,
    required this.phone,
    required this.unitName,
    required this.unitSub,
    this.productName,
    this.projectName,
    this.townshipName,
    this.price,
    required this.canTopup,
    this.canEdit = true,
    this.canDelete = true,
    required this.rejected,
    this.rejectStage,
    this.rejectReason,
    this.rejectFixIsCustomerData = false,
    required this.timeline,
    required this.customer,
    required this.requiredDocs,
    required this.docsUploaded,
    this.docAttachmentTypeIds = const {},
    this.docAttachments = const {},
    required this.notes,
    this.totalPaidSoFar = 2000000,
    this.reserveNote,
    this.caraBayarId,
    this.caraBayarName,
  });

  /// Backend cuma expose satu `is_rejected` gabungan (SA ATAU Kasir) tanpa membedakan sumbernya,
  /// dan cuma `update` (Perbaiki Data Customer) yang mereset flag penolakan di kedua sisi — jadi
  /// untuk kasus Ditolak apa pun, "Perbaiki Data Customer" adalah satu-satunya aksi yang benar2
  /// mengeluarkan order dari status Ditolak.
  factory ReserveOrderDetail.fromEntity(ReserveOrderDetailEntity e) {
    final initials = e.customerName.trim().isEmpty
        ? '-'
        : e.customerName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((s) => s[0].toUpperCase())
              .join();

    final docAttachments = <String, List<ReserveOrderAttachmentEntity>>{};
    for (final d in e.requiredDocs) {
      final candidates = e.attachments
          .where(
            (a) =>
                a.attachmentTypeId == d.attachmentTypeId &&
                (a.attachmentPath ?? '').isNotEmpty,
          )
          .toList();
      if (candidates.isEmpty) continue;
      candidates.sort((a, b) {
        final byDate = (b.createDatetime ?? DateTime(0)).compareTo(
          a.createDatetime ?? DateTime(0),
        );
        return byDate != 0
            ? byDate
            : b.contactAttachmentId.compareTo(a.contactAttachmentId);
      });
      docAttachments[d.name] = candidates;
    }

    return ReserveOrderDetail(
      reserveOrderId: e.reserveOrderId,
      contactId: e.contactId,
      customerName: e.customerName,
      avatarInitials: initials,
      phone: e.phoneNumber ?? '-',
      unitName: e.unitName ?? '-',
      unitSub: [
        e.townshipName,
        e.unitSub,
        e.productName,
      ].where((s) => (s ?? '').trim().isNotEmpty).join(' · '),
      productName: e.productName,
      projectName: e.unitSub,
      townshipName: e.townshipName,
      canTopup: e.canTopup,
      canEdit: e.canEdit,
      canDelete: e.canDelete,
      rejected: e.isRejected,
      rejectStage: e.rejectStage,
      rejectReason: e.rejectReason,
      rejectFixIsCustomerData: e.isRejected,
      timeline: e.timeline
          .map(
            (s) => ReserveOrderTimelineStep(
              label: s.label,
              sub: s.sub,
              status: switch (s.status) {
                ReserveOrderStageStatus.done => ReserveOrderStepStatus.done,
                ReserveOrderStageStatus.active => ReserveOrderStepStatus.active,
                ReserveOrderStageStatus.todo => ReserveOrderStepStatus.todo,
              },
            ),
          )
          .toList(),
      customer: ReserveOrderCustomerData(raw: e.customer),
      requiredDocs: e.requiredDocs.map((d) => d.name).toList(),
      docsUploaded: {for (final d in e.requiredDocs) d.name: d.uploaded},
      docAttachmentTypeIds: {
        for (final d in e.requiredDocs) d.name: d.attachmentTypeId,
      },
      docAttachments: docAttachments,
      notes: e.messages
          .map(
            (m) => ReserveOrderChatMessage(
              who: m.who,
              isMe: m.isMe,
              time: m.time ?? '',
              text: m.text,
              color: const Color(primaryColor),
            ),
          )
          .toList(),
      totalPaidSoFar: e.totalPaidSoFar.round(),
      reserveNote: e.reserveNote,
      caraBayarId: e.caraBayarId,
      caraBayarName: e.caraBayarName,
    );
  }
}
