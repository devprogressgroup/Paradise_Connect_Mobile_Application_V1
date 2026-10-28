import 'package:progress_group/features/reserve-order/data/models/reserve_order_questionnaire_model.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';

class ReserveOrderTimelineStepModel extends ReserveOrderTimelineStepEntity {
  const ReserveOrderTimelineStepModel({
    required super.code,
    required super.label,
    super.sub,
    required super.status,
    super.latestMessage,
    super.cancelLabel,
    super.tts,
  });

  factory ReserveOrderTimelineStepModel.fromJson(Map<String, dynamic> json) {
    // `is Map` — PHP bisa kirim `[]` (bukan null) kalau kosong.
    final msg = json['latest_message'];
    final msgMap = msg is Map<String, dynamic> ? msg : null;
    final msgText = (msgMap?['text'] as String?)?.trim() ?? '';
    final cancelLabel = (json['cancel_label'] as String?)?.trim() ?? '';
    return ReserveOrderTimelineStepModel(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sub: json['sub'] as String?,
      status: reserveOrderStageStatusFromApi(json['status'] as String?),
      latestMessage: msgText.isEmpty
          ? null
          : ReserveOrderTimelineMessageEntity(
              text: msgText,
              who: msgMap!['who'] as String?,
              time: msgMap['time'] as String?,
            ),
      cancelLabel: cancelLabel.isEmpty ? null : cancelLabel,
      tts: ((json['tts'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (t) => ReserveOrderTimelineTtsEntity(
              ttsNumber: t['tts_number']?.toString(),
              paymentTypeName: t['payment_type_name'] as String?,
              amount: (t['amount'] as num?)?.toDouble() ?? 0,
              ttsDate: t['tts_date'] as String?,
              paymentStatus: t['payment_status'] as String? ?? 'pending',
              paymentLabel: t['payment_label'] as String? ?? '',
            ),
          )
          .toList(),
    );
  }
}

class ReserveOrderRequiredDocModel extends ReserveOrderRequiredDocEntity {
  const ReserveOrderRequiredDocModel({
    required super.attachmentTypeId,
    required super.name,
    required super.uploaded,
  });

  factory ReserveOrderRequiredDocModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderRequiredDocModel(
      attachmentTypeId: json['attachment_type_id'] as int,
      name: json['name'] as String? ?? '-',
      uploaded: json['uploaded'] == true,
    );
  }
}

class ReserveOrderAttachmentModel extends ReserveOrderAttachmentEntity {
  const ReserveOrderAttachmentModel({
    required super.contactAttachmentId,
    super.attachmentTypeId,
    super.attachmentPath,
    super.reserveOrderTtsId,
    super.verificationStatus,
    super.verificationNote,
    super.attachmentNote,
    super.createDatetime,
    super.isVerifiable,
    super.locked,
  });

  /// attachment_type_id yang diverifikasi Kasir: 1 KTP Pemohon, 15 Bukti Transfer — fallback kalau
  /// server belum mengirim `is_verifiable`.
  static const _verifiableTypeIds = {1, 15};

  factory ReserveOrderAttachmentModel.fromJson(Map<String, dynamic> json) {
    final typeId = json['attachment_type_id'] as int?;
    return ReserveOrderAttachmentModel(
      contactAttachmentId: json['contact_attachment_id'] as int,
      attachmentTypeId: typeId,
      attachmentPath: json['attachment_path'] as String?,
      reserveOrderTtsId: json['reserve_order_tts_id'] as int?,
      verificationStatus: json['verification_status'] as String?,
      verificationNote: json['verification_note'] as String?,
      attachmentNote: json['attachment_note'] as String?,
      createDatetime: DateTime.tryParse(
        json['create_datetime'] as String? ?? '',
      ),
      isVerifiable: json['is_verifiable'] as bool? ?? _verifiableTypeIds.contains(typeId),
      locked: json['locked'] == true,
    );
  }
}

class ReserveOrderTtsItemModel extends ReserveOrderTtsItemEntity {
  const ReserveOrderTtsItemModel({
    required super.reserveOrderTtsDetailId,
    super.paymentMethod,
    super.amount,
    super.bankName,
    super.referenceNumber,
  });

  factory ReserveOrderTtsItemModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderTtsItemModel(
      reserveOrderTtsDetailId: json['reserve_order_tts_detail_id'] as int,
      paymentMethod: json['payment_method'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      bankName: json['bank_name'] as String?,
      referenceNumber: json['reference_number'] as String?,
    );
  }
}

class ReserveOrderTtsModel extends ReserveOrderTtsEntity {
  const ReserveOrderTtsModel({
    required super.reserveOrderTtsId,
    required super.ttsNumber,
    super.ttsType,
    super.paymentTypeId,
    super.ttsAmountRp,
    super.ttsAmountRpInWords,
    super.isApproved,
    super.ttsDate,
    super.note,
    super.items,
  });

  factory ReserveOrderTtsModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return ReserveOrderTtsModel(
      reserveOrderTtsId: json['reserve_order_tts_id'] as int,
      ttsNumber: json['tts_number'] as String? ?? '',
      ttsType: json['tts_type'] as String?,
      paymentTypeId: json['payment_type_id'] as int?,
      ttsAmountRp: (json['tts_amount_rp'] as num?)?.toDouble() ?? 0,
      ttsAmountRpInWords: json['tts_amount_rp_in_words'] as String?,
      isApproved: json['is_approved'] as bool?,
      ttsDate: DateTime.tryParse(json['tts_date'] as String? ?? ''),
      note: json['note'] as String?,
      items: items
          .map(
            (e) => ReserveOrderTtsItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ReserveOrderResubmitModel extends ReserveOrderResubmitEntity {
  const ReserveOrderResubmitModel({
    super.reserveDate,
    super.unitEditable,
    super.unitLockedReason,
    super.tts,
  });

  // Kolom decimal Laravel bisa terkirim sbg string ("3000000.00").
  static double _double(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  static int? _int(Object? v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  factory ReserveOrderResubmitModel.fromJson(Map<String, dynamic> json) {
    final tts = json['tts'];
    return ReserveOrderResubmitModel(
      reserveDate: DateTime.tryParse(json['reserve_date'] as String? ?? ''),
      unitEditable: json['unit_editable'] == true,
      unitLockedReason: json['unit_locked_reason'] as String?,
      tts: tts is Map<String, dynamic> ? _tts(tts) : null,
    );
  }

  static ReserveOrderResubmitTtsEntity _tts(Map<String, dynamic> json) {
    return ReserveOrderResubmitTtsEntity(
      reserveOrderTtsId: _int(json['reserve_order_tts_id']) ?? 0,
      ttsNumber: json['tts_number']?.toString() ?? '',
      paymentTypeId: _int(json['payment_type_id']),
      editable: json['editable'] == true,
      lockedReason: json['locked_reason'] as String?,
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => ReserveOrderResubmitPaymentEntity(
              paymentMethod: p['payment_method']?.toString() ?? '',
              amount: _double(p['amount']),
              bankId: _int(p['bank_id']),
              bankName: p['bank_name'] as String?,
              cardNetwork: p['card_network'] as String?,
              referenceNumber: p['reference_number']?.toString(),
              referenceDate: DateTime.tryParse(
                p['reference_date'] as String? ?? '',
              ),
              tunaiDeposited:
                  p['tunai_deposited'] == true || p['tunai_deposited'] == 1,
            ),
          )
          .toList(),
      proofs: ((json['proofs'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((p) => _int(p['contact_attachment_id']) != null)
          .map(
            (p) => ReserveOrderResubmitProofEntity(
              contactAttachmentId: _int(p['contact_attachment_id'])!,
              attachmentPath: p['attachment_path'] as String?,
              verificationStatus: p['verification_status'] as String?,
            ),
          )
          .toList(),
    );
  }
}

class ReserveOrderMessageModel extends ReserveOrderMessageEntity {
  const ReserveOrderMessageModel({
    required super.who,
    super.isMe,
    super.time,
    required super.text,
    super.attachmentUrl,
    super.attachmentName,
    super.customer,
    super.contactedBy,
    super.status,
    super.followUp,
  });

  factory ReserveOrderMessageModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderMessageModel(
      who: json['who'] as String? ?? 'System',
      isMe: json['is_me'] == true,
      time: json['time'] as String?,
      text: json['text'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      customer: json['customer'] as String?,
      contactedBy: json['contacted_by'] as String?,
      status: json['status'] as String?,
      followUp: json['follow_up'] as String?,
    );
  }
}

class ReserveOrderSalesModel extends ReserveOrderSalesEntity {
  const ReserveOrderSalesModel({
    super.executive,
    super.supervisor,
    super.manager,
    super.generalManager,
  });

  factory ReserveOrderSalesModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderSalesModel(
      executive: json['executive'] as String?,
      supervisor: json['supervisor'] as String?,
      manager: json['manager'] as String?,
      generalManager: json['general_manager'] as String?,
    );
  }
}

class ReserveOrderDetailModel extends ReserveOrderDetailEntity {
  const ReserveOrderDetailModel({
    required super.reserveOrderId,
    super.contactId,
    required super.customerName,
    super.phoneNumber,
    super.unitName,
    super.unitSub,
    super.productName,
    super.townshipName,
    super.townshipId,
    super.caraBayarName,
    super.canTopup,
    super.canChangeUnit,
    super.topupLockedReason,
    super.editLockedReason,
    super.docLockedReason,
    super.deleteLockedReason,
    super.canEdit,
    super.canDelete,
    super.statusLabel,
    super.isRejected,
    super.rejectStage,
    super.rejectReason,
    super.rejectSource,
    super.canResubmit,
    super.resubmit,
    super.timeline,
    super.customer,
    super.questionnaire,
    super.requiredDocs,
    super.attachments,
    super.ttsList,
    super.totalPaidSoFar,
    super.messages,
    super.sales,
    super.reserveNote,
    super.caraBayarId,
    super.propertyId,
    super.productId,
    super.companyId,
  });

  factory ReserveOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final timeline = json['timeline'] as List<dynamic>? ?? const [];
    final requiredDocs = json['required_docs'] as List<dynamic>? ?? const [];
    final attachments = json['attachments'] as List<dynamic>? ?? const [];
    final ttsList = json['tts_list'] as List<dynamic>? ?? const [];
    final messages = json['messages'] as List<dynamic>? ?? const [];

    return ReserveOrderDetailModel(
      reserveOrderId: json['reserve_order_id'] as int,
      contactId: json['contact_id'] as int?,
      customerName: json['customer_name'] as String? ?? '-',
      phoneNumber: json['phone_number'] as String?,
      unitName: json['property_name'] as String?,
      unitSub: json['project_name'] as String?,
      productName: json['product_name'] as String?,
      townshipName: json['township_name'] as String?,
      townshipId: (json['township_id'] as num?)?.toInt(),
      caraBayarName: json['cara_bayar_name'] as String?,
      canTopup: json['can_topup'] == true,
      canChangeUnit: json['can_change_unit'] == true,
      topupLockedReason: json['topup_locked_reason'] as String?,
      editLockedReason: json['edit_locked_reason'] as String?,
      docLockedReason: json['doc_locked_reason'] as String?,
      deleteLockedReason: json['delete_locked_reason'] as String?,
      // Default true bila backend lama belum kirim flag — server tetap menolak (403) bila tak berhak.
      canEdit: json['can_edit'] != false,
      canDelete: json['can_delete'] != false,
      statusLabel: json['status_label'] as String?,
      isRejected: json['is_rejected'] == true,
      rejectStage: json['reject_stage'] as String?,
      rejectReason: json['reject_reason'] as String?,
      rejectSource: json['reject_source'] as String?,
      canResubmit: json.containsKey('can_resubmit')
          ? json['can_resubmit'] == true
          : null,
      resubmit: json['resubmit'] is Map<String, dynamic>
          ? ReserveOrderResubmitModel.fromJson(
              json['resubmit'] as Map<String, dynamic>,
            )
          : null,
      timeline: timeline
          .map(
            (e) =>
                ReserveOrderTimelineStepModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      customer: json['customer'] as Map<String, dynamic>? ?? const {},
      questionnaire: json['questionnaire'] is Map<String, dynamic>
          ? ReserveQuestionnaireModel.fromJson(
              json['questionnaire'] as Map<String, dynamic>,
            )
          : null,
      requiredDocs: requiredDocs
          .map(
            (e) =>
                ReserveOrderRequiredDocModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      attachments: attachments
          .map(
            (e) =>
                ReserveOrderAttachmentModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      ttsList: ttsList
          .map((e) => ReserveOrderTtsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPaidSoFar: (json['total_paid_so_far'] as num?)?.toDouble() ?? 0,
      messages: messages
          .map(
            (e) => ReserveOrderMessageModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      sales: ReserveOrderSalesModel.fromJson(
        json['sales'] as Map<String, dynamic>? ?? const {},
      ),
      reserveNote: json['reserve_note'] as String?,
      caraBayarId: json['cara_bayar_id'] as int?,
      propertyId: json['property_id'] as int?,
      productId: json['product_id'] as int?,
      companyId: json['company_id'] as int?,
    );
  }
}
