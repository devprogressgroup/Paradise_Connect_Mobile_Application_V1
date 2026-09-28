import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';

class ContactDetailArgs {
  final ContactAttachment? dataAttachment;
  final ContactEntity? dataContact;
  final ActivityEntity? dataActivity;
  final CreateContactParams? createContactParams;
  final int page;
  final String? namePage;
  final int initialTab;
  final String? sourceRoute;
  final String? focusField;
  final String? buttonLabel;

  /// Diisi kalau flow attachment (page 5) ini dibuka dari Reserve Order (tab Attachment, tap salah
  /// satu dokumen wajib) — supaya upload-nya ikut kehitung di `required_docs.uploaded` order itu
  /// (lihat `UploadAttachmentParams.reserveOrderId`), bukan cuma nempel ke contact_id.
  final int? reserveOrderId;

  /// TTS (`reserve_order_tts_id`) file yang di-"Upload Ulang" (page 7) — dikirim ulang di
  /// `PATCH /contacts/{contact_id}/attachments/{id}` supaya tetap tertaut ke TTS yang sama.
  final int? reserveOrderTtsId;

  /// Attachment Type yang harus dipakai (mis. "Form Visitor") kalau dokumennya sudah ditentukan
  /// dari baris yang di-tap — dropdown "Attachment Type" langsung ke-preset & dikunci (tidak bisa
  /// diganti) supaya upload-nya benar2 masuk ke slot dokumen wajib yang dimaksud.
  final int? initialAttachmentTypeId;
  final String? initialAttachmentTypeName;

  ContactDetailArgs({
    this.dataAttachment,
    this.dataContact,
    this.dataActivity,
    this.createContactParams,
    this.page = 0, // 0: create 1: edit
    this.namePage,
    this.initialTab = 0,
    this.sourceRoute,
    this.focusField,
    this.buttonLabel,
    this.reserveOrderId,
    this.reserveOrderTtsId,
    this.initialAttachmentTypeId,
    this.initialAttachmentTypeName,
  });

  ContactDetailArgs copyWith({
    ContactAttachment? dataAttachment,
    ContactEntity? dataContact,
    ActivityEntity? dataActivity,
    CreateContactParams? createContactParams,
    int? page,
    String? namePage,
    int? initialTab,
    String? sourceRoute,
    String? focusField,
    String? buttonLabel,
    int? reserveOrderId,
    int? reserveOrderTtsId,
    int? initialAttachmentTypeId,
    String? initialAttachmentTypeName,
  }) {
    return ContactDetailArgs(
      dataAttachment: dataAttachment ?? this.dataAttachment,
      dataContact: dataContact ?? this.dataContact,
      dataActivity: dataActivity ?? this.dataActivity,
      createContactParams: createContactParams ?? this.createContactParams,
      page: page ?? this.page,
      namePage: namePage ?? this.namePage,
      initialTab: initialTab ?? this.initialTab,
      sourceRoute: sourceRoute ?? this.sourceRoute,
      focusField: focusField ?? this.focusField,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      reserveOrderId: reserveOrderId ?? this.reserveOrderId,
      reserveOrderTtsId: reserveOrderTtsId ?? this.reserveOrderTtsId,
      initialAttachmentTypeId:
          initialAttachmentTypeId ?? this.initialAttachmentTypeId,
      initialAttachmentTypeName:
          initialAttachmentTypeName ?? this.initialAttachmentTypeName,
    );
  }
}
