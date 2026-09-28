import 'dart:io';

import 'dart:typed_data';

class UploadAttachmentParams {
  final int contactId;
  final int? dealId;
  final int? activityId;

  /// Diisi kalau upload-nya datang dari halaman Reserve Order — supaya dokumen ikut kehitung di
  /// `required_docs.uploaded` (`ReserveOrderService::getDetail`), bukan cuma nempel ke contact_id.
  final int? reserveOrderId;

  /// TTS (`reserve_order_tts_id`) pemilik file ini — dikirim ulang saat "Upload Ulang" dokumen
  /// TTS/bukti bayar di Reserve Order supaya file penggantinya tetap tertaut ke TTS yang sama.
  final int? reserveOrderTtsId;
  final int attachmentTypeId;
  final String? attachmentNote;

  final File? file;
  final Uint8List? fileBytes;
  final String? fileName;

  final List<Uint8List>? filesBytesList;
  final List<String>? fileNames;

  UploadAttachmentParams({
    required this.contactId,
    this.dealId,
    this.activityId,
    this.reserveOrderId,
    this.reserveOrderTtsId,
    required this.attachmentTypeId,
    this.attachmentNote,
    this.file,
    this.fileBytes,
    this.fileName,
    this.filesBytesList,
    this.fileNames,
  });
}
