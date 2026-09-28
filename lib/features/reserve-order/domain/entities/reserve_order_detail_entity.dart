import 'package:equatable/equatable.dart';

enum ReserveOrderStageStatus { done, active, todo }

ReserveOrderStageStatus reserveOrderStageStatusFromApi(String? value) {
  switch (value) {
    case 'done':
      return ReserveOrderStageStatus.done;
    case 'active':
      return ReserveOrderStageStatus.active;
    default:
      return ReserveOrderStageStatus.todo;
  }
}

/// Satu langkah timeline (10 tahap) — hasil `ReserveOrderService::buildTimeline`.
class ReserveOrderTimelineStepEntity extends Equatable {
  final String code;
  final String label;
  final String? sub;
  final ReserveOrderStageStatus status;

  const ReserveOrderTimelineStepEntity({
    required this.code,
    required this.label,
    this.sub,
    required this.status,
  });

  @override
  List<Object?> get props => [code, label, sub, status];
}

class ReserveOrderRequiredDocEntity extends Equatable {
  final int attachmentTypeId;
  final String name;
  final bool uploaded;

  const ReserveOrderRequiredDocEntity({
    required this.attachmentTypeId,
    required this.name,
    required this.uploaded,
  });

  @override
  List<Object?> get props => [attachmentTypeId, name, uploaded];
}

class ReserveOrderAttachmentEntity extends Equatable {
  final int contactAttachmentId;
  final int? attachmentTypeId;
  final String? attachmentPath;
  final int? reserveOrderTtsId;
  final String? verificationStatus;
  final String? verificationNote;
  final DateTime? createDatetime;

  const ReserveOrderAttachmentEntity({
    required this.contactAttachmentId,
    this.attachmentTypeId,
    this.attachmentPath,
    this.reserveOrderTtsId,
    this.verificationStatus,
    this.verificationNote,
    this.createDatetime,
  });

  bool get isRejected => verificationStatus == 'rejected';

  @override
  List<Object?> get props => [
    contactAttachmentId,
    attachmentTypeId,
    attachmentPath,
    reserveOrderTtsId,
    verificationStatus,
    verificationNote,
    createDatetime,
  ];
}

class ReserveOrderTtsItemEntity extends Equatable {
  final int reserveOrderTtsDetailId;
  final String? paymentMethod;
  final double amount;
  final String? bankName;
  final String? referenceNumber;

  const ReserveOrderTtsItemEntity({
    required this.reserveOrderTtsDetailId,
    this.paymentMethod,
    this.amount = 0,
    this.bankName,
    this.referenceNumber,
  });

  @override
  List<Object?> get props => [
    reserveOrderTtsDetailId,
    paymentMethod,
    amount,
    bankName,
    referenceNumber,
  ];
}

class ReserveOrderTtsEntity extends Equatable {
  final int reserveOrderTtsId;
  final String ttsNumber;
  final String? ttsType;
  final int? paymentTypeId;
  final double ttsAmountRp;
  final String? ttsAmountRpInWords;
  final bool? isApproved;
  final DateTime? ttsDate;
  final String? note;
  final List<ReserveOrderTtsItemEntity> items;

  const ReserveOrderTtsEntity({
    required this.reserveOrderTtsId,
    required this.ttsNumber,
    this.ttsType,
    this.paymentTypeId,
    this.ttsAmountRp = 0,
    this.ttsAmountRpInWords,
    this.isApproved,
    this.ttsDate,
    this.note,
    this.items = const [],
  });

  @override
  List<Object?> get props => [
    reserveOrderTtsId,
    ttsNumber,
    ttsType,
    paymentTypeId,
    ttsAmountRp,
    ttsAmountRpInWords,
    isApproved,
    ttsDate,
    note,
    items,
  ];
}

class ReserveOrderMessageEntity extends Equatable {
  final String who;
  final bool isMe;
  final String? time;
  final String text;

  const ReserveOrderMessageEntity({
    required this.who,
    this.isMe = false,
    this.time,
    required this.text,
  });

  @override
  List<Object?> get props => [who, isMe, time, text];
}

class ReserveOrderSalesEntity extends Equatable {
  final String? executive;
  final String? supervisor;
  final String? manager;
  final String? generalManager;

  const ReserveOrderSalesEntity({
    this.executive,
    this.supervisor,
    this.manager,
    this.generalManager,
  });

  @override
  List<Object?> get props => [executive, supervisor, manager, generalManager];
}

/// Hasil `GET /reserve-order/detail/{id}` — juga dipakai sbg balikan `update`/`topup`
/// (`ReserveOrderService::updateCustomer`/`topup` sama-sama return `getDetail()`).
class ReserveOrderDetailEntity extends Equatable {
  final int reserveOrderId;

  /// contact_id (m_contacts) pemilik reserve order ini — dipakai untuk upload dokumen tambahan
  /// lewat endpoint generik `POST /contacts/{contact_id}/attachments` (lihat [ReserveOrderRequiredDocEntity]).
  final int? contactId;
  final String customerName;
  final String? phoneNumber;
  final String? unitName;

  /// `project_name` (cluster), mis. "Cluster EcoArdence".
  final String? unitSub;
  final String? productName;
  final String? townshipName;
  final String? caraBayarName;
  final bool canTopup;
  final String? statusLabel;
  final bool isRejected;
  final String? rejectStage;
  final String? rejectReason;
  final List<ReserveOrderTimelineStepEntity> timeline;

  /// Row `m_customer_reserve` apa adanya (cocok langsung dgn `ReserveOrderCustomerData.raw`).
  final Map<String, dynamic> customer;
  final List<ReserveOrderRequiredDocEntity> requiredDocs;
  final List<ReserveOrderAttachmentEntity> attachments;
  final List<ReserveOrderTtsEntity> ttsList;
  final double totalPaidSoFar;
  final List<ReserveOrderMessageEntity> messages;
  final ReserveOrderSalesEntity sales;

  /// Nilai APA ADANYA field-field yang bisa diedit lewat `ReserveOrderController::edit` — dipakai
  /// buat prefill form "Edit Reserve Order" (beda dari [caraBayarName] yang cuma nama tampilan).
  final String? reserveNote;
  final int? caraBayarId;
  final int? propertyId;
  final int? productId;
  final int? companyId;

  const ReserveOrderDetailEntity({
    required this.reserveOrderId,
    this.contactId,
    required this.customerName,
    this.phoneNumber,
    this.unitName,
    this.unitSub,
    this.productName,
    this.townshipName,
    this.caraBayarName,
    this.canTopup = false,
    this.statusLabel,
    this.isRejected = false,
    this.rejectStage,
    this.rejectReason,
    this.timeline = const [],
    this.customer = const {},
    this.requiredDocs = const [],
    this.attachments = const [],
    this.ttsList = const [],
    this.totalPaidSoFar = 0,
    this.messages = const [],
    this.sales = const ReserveOrderSalesEntity(),
    this.reserveNote,
    this.caraBayarId,
    this.propertyId,
    this.productId,
    this.companyId,
  });

  @override
  List<Object?> get props => [
    reserveOrderId,
    contactId,
    customerName,
    phoneNumber,
    unitName,
    unitSub,
    productName,
    townshipName,
    caraBayarName,
    reserveNote,
    caraBayarId,
    propertyId,
    productId,
    companyId,
    canTopup,
    statusLabel,
    isRejected,
    rejectStage,
    rejectReason,
    timeline,
    customer,
    requiredDocs,
    attachments,
    ttsList,
    totalPaidSoFar,
    messages,
    sales,
  ];
}
