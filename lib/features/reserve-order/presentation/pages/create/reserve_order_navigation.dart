import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';
import 'index.dart';

String? _reserveOrderGenderFromSalutation(String? salutation) {
  switch (salutation) {
    case 'Bapak':
      return 'Laki-laki';
    case 'Ibu':
      return 'Perempuan';
    default:
      return null;
  }
}

ContactAttachment? _matchAttachment(
  List<ContactAttachment> attachments,
  String keyword,
) {
  for (final a in attachments) {
    if (a.attachmentTypeName.toLowerCase().contains(keyword)) return a;
  }
  return null;
}

/// Buka wizard Create Reserve Order dengan data default dari [contact] (nama — Name SP kalau ada, no HP, No. KTP,
/// alamat, jenis kelamin dari salutation, sales channel, project terakhir, riwayat unit) dan,
/// kalau [attachments] diisi, attachment KTP/NPWP yang sudah ada supaya tidak perlu upload ulang.
/// [initialCustomer] (data `customer` dari detail Reserve Order sebelumnya) menimpa data contact
/// supaya field seperti tempat/tanggal lahir, pekerjaan, dan cara bayar ikut terisi.
///
/// Dipakai dari dua entry point: tombol "Reserve Order" di Log Activity Contact Detail, dan
/// halaman pilih Contact (`SelectContactForReserveOrderPage`) saat masuk lewat FAB list Reserve
/// Order — keduanya butuh `contact.contactId` supaya tab "Unit dari Contact" bisa panggil
/// `GET /reserve-order/select-unit`.
void navigateToCreateReserveOrder(
  BuildContext context, {
  required ContactEntity contact,
  List<ContactAttachment> attachments = const [],
  Map<String, dynamic>? initialCustomer,
  bool replace = false,
  bool notifyPendingProspectStatus = false,
}) {
  // Gate fitur 'Create' form "Reserve Order" (software Mobile). Server juga menolak (403).
  if (!PermissionsHelper.canCreateReserveOrder) {
    showSnackbar(context, 'Anda tidak memiliki akses membuat Reserve Order.', isError: true);
    return;
  }

  final contactId = contact.contactId;
  if (contactId == null) return;

  // "KTP Pemohon" didahulukan — tipe "KTP Pendukung" juga mengandung kata 'ktp'.
  final ktp =
      _matchAttachment(attachments, 'ktp pemohon') ??
      _matchAttachment(attachments, 'ktp');
  final npwp = _matchAttachment(attachments, 'npwp');

  // Name SP (t_deals.name_sp deal terakhir, diisi di form Update Status) didahulukan utk "Nama
  // Lengkap (sesuai KTP)" — kosong → nama contact seperti biasa.
  final nameSp = contact.nameSP?.trim() ?? '';

  final route = MaterialPageRoute<void>(
    builder: (_) => CreateReserveOrderPage(
      contactId: contactId,
      contactName: nameSp.isNotEmpty ? nameSp : contact.fullName,
      contactPhone: contact.whatsappNumber ?? contact.primaryPhone,
      contactKtpNumber: contact.noKtp,
      contactAddress: contact.ktpAddress,
      contactGender: _reserveOrderGenderFromSalutation(contact.salutation),
      salesChannel: contact.sumberInformasi1,
      salesChannelDetail: contact.sumberInformasi2Name,
      contactProjectId: contact.lastProjectId,
      contactUnits: contact.units,
      existingKtpAttachmentUrl: ktp?.attachmentUrl,
      existingNpwpAttachmentUrl: npwp?.attachmentUrl,
      existingKtpAttachmentId: ktp?.contactAttachmentId,
      existingNpwpAttachmentId: npwp?.contactAttachmentId,
      salesExecutiveId: contact.salesExecutiveId,
      salesExecutiveName: contact.salesExecutiveName,
      salesSupervisorId: contact.salesSupervisorId,
      salesSupervisorName: contact.salesSupervisorName,
      salesManagerId: contact.salesManagerId,
      salesManagerName: contact.salesManagerName,
      salesGeneralManagerId: contact.salesGeneralManagerId,
      salesGeneralManagerName: contact.salesGeneralManagerName,
      salesTeamId: contact.salesTeamId,
      salesTeamName: contact.salesTeamName,
      initialCustomer: initialCustomer,
      notifyPendingProspectStatus: notifyPendingProspectStatus,
    ),
  );

  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

/// `attachment_type_id` KTP Pemohon & NPWP (`ReserveOrderService::ATTACHMENT_TYPE_KTP/NPWP`).
const _ktpAttachmentTypeId = 1;
const _npwpAttachmentTypeId = 6;

/// Buka wizard Create Reserve Order mode "Pengajuan Ulang" (tombol di Detail RO Ditolak) — semua
/// field diisi dari [detail]: customer, unit, KTP/NPWP yang dipakai sekarang, dan `resubmit` (TTS,
/// Tanggal Reserve, kunci unit). Balik `message` server kalau berhasil diajukan ulang, null kalau batal.
Future<String?> navigateToResubmitReserveOrder(
  BuildContext context,
  ReserveOrderDetailEntity detail,
) {
  ReserveOrderAttachmentEntity? latest(int typeId) {
    final files = detail.attachments
        .where(
          (a) =>
              a.attachmentTypeId == typeId &&
              (a.attachmentPath ?? '').isNotEmpty,
        )
        .toList();
    if (files.isEmpty) return null;
    files.sort((a, b) {
      final byDate = (b.createDatetime ?? DateTime(0)).compareTo(
        a.createDatetime ?? DateTime(0),
      );
      return byDate != 0
          ? byDate
          : b.contactAttachmentId.compareTo(a.contactAttachmentId);
    });
    return files.first;
  }

  final ktp = latest(_ktpAttachmentTypeId);
  final npwp = latest(_npwpAttachmentTypeId);
  final customer = detail.customer;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => CreateReserveOrderPage(
        contactId: detail.contactId ?? 0,
        contactName: detail.customerName,
        contactPhone: detail.phoneNumber,
        salesChannel: customer['sales_channel']?.toString(),
        salesChannelDetail: customer['sales_channel_detail']?.toString(),
        existingKtpAttachmentUrl: ktp?.attachmentPath,
        existingKtpAttachmentId: ktp?.contactAttachmentId,
        existingNpwpAttachmentUrl: npwp?.attachmentPath,
        existingNpwpAttachmentId: npwp?.contactAttachmentId,
        salesExecutiveName: detail.sales.executive,
        salesSupervisorName: detail.sales.supervisor,
        salesManagerName: detail.sales.manager,
        salesGeneralManagerName: detail.sales.generalManager,
        initialCustomer: {
          ...customer,
          if (detail.caraBayarId != null) 'cara_bayar_id': detail.caraBayarId,
          if ((detail.caraBayarName ?? '').isNotEmpty)
            'cara_bayar_name': detail.caraBayarName,
        },
        resubmitOrder: detail,
      ),
    ),
  );
}
