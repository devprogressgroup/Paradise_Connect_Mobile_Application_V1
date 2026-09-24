import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';

class ReserveOrderTimelineStepModel extends ReserveOrderTimelineStepEntity {
  const ReserveOrderTimelineStepModel({
    required super.code,
    required super.label,
    super.sub,
    required super.status,
  });

  factory ReserveOrderTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderTimelineStepModel(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sub: json['sub'] as String?,
      status: reserveOrderStageStatusFromApi(json['status'] as String?),
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
    super.createDatetime,
  });

  factory ReserveOrderAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderAttachmentModel(
      contactAttachmentId: json['contact_attachment_id'] as int,
      attachmentTypeId: json['attachment_type_id'] as int?,
      attachmentPath: json['attachment_path'] as String?,
      reserveOrderTtsId: json['reserve_order_tts_id'] as int?,
      verificationStatus: json['verification_status'] as String?,
      createDatetime: DateTime.tryParse(
        json['create_datetime'] as String? ?? '',
      ),
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

class ReserveOrderMessageModel extends ReserveOrderMessageEntity {
  const ReserveOrderMessageModel({
    required super.who,
    super.isMe,
    super.time,
    required super.text,
  });

  factory ReserveOrderMessageModel.fromJson(Map<String, dynamic> json) {
    return ReserveOrderMessageModel(
      who: json['who'] as String? ?? 'System',
      isMe: json['is_me'] == true,
      time: json['time'] as String?,
      text: json['text'] as String? ?? '',
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
    super.caraBayarName,
    super.canTopup,
    super.statusLabel,
    super.isRejected,
    super.rejectStage,
    super.rejectReason,
    super.timeline,
    super.customer,
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
      caraBayarName: json['cara_bayar_name'] as String?,
      canTopup: json['can_topup'] == true,
      statusLabel: json['status_label'] as String?,
      isRejected: json['is_rejected'] == true,
      rejectStage: json['reject_stage'] as String?,
      rejectReason: json['reject_reason'] as String?,
      timeline: timeline
          .map(
            (e) =>
                ReserveOrderTimelineStepModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      customer: json['customer'] as Map<String, dynamic>? ?? const {},
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
