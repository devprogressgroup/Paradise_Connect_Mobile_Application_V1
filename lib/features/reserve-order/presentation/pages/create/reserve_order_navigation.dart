import 'package:flutter/material.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
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

/// Buka wizard Create Reserve Order dengan data default dari [contact] (nama, no HP, No. KTP,
/// alamat, jenis kelamin dari salutation, sales channel, project terakhir, riwayat unit) dan,
/// kalau [attachments] diisi, attachment KTP/NPWP yang sudah ada supaya tidak perlu upload ulang.
///
/// Dipakai dari dua entry point: tombol "Reserve Order" di Log Activity Contact Detail, dan
/// halaman pilih Contact (`SelectContactForReserveOrderPage`) saat masuk lewat FAB list Reserve
/// Order — keduanya butuh `contact.contactId` supaya tab "Unit dari Contact" bisa panggil
/// `GET /reserve-order/select-unit`.
void navigateToCreateReserveOrder(
  BuildContext context, {
  required ContactEntity contact,
  List<ContactAttachment> attachments = const [],
  bool replace = false,
}) {
  final contactId = contact.contactId;
  if (contactId == null) return;

  final ktp = _matchAttachment(attachments, 'ktp');
  final npwp = _matchAttachment(attachments, 'npwp');

  final route = MaterialPageRoute<void>(
    builder: (_) => CreateReserveOrderPage(
      contactId: contactId,
      contactName: contact.fullName,
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
    ),
  );

  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}
