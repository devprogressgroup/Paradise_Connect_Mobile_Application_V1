import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_questionnaire_entity.dart';

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

/// Pesan terakhir pada satu tahap timeline (`latest_message`) — `time` sudah diformat server.
class ReserveOrderTimelineMessageEntity extends Equatable {
  final String text;
  final String? who;
  final String? time;

  const ReserveOrderTimelineMessageEntity({
    required this.text,
    this.who,
    this.time,
  });

  @override
  List<Object?> get props => [text, who, time];
}

/// Satu TTS di rincian tahap timeline (`tts`) — `paymentStatus` = verifikasi pembayaran Kasir per
/// TTS (`approved` / `rejected` / `pending`), teksnya dari server ([paymentLabel]).
class ReserveOrderTimelineTtsEntity extends Equatable {
  final String? ttsNumber;
  final String? paymentTypeName;
  final double amount;
  final String? ttsDate;
  final String paymentStatus;
  final String paymentLabel;

  const ReserveOrderTimelineTtsEntity({
    this.ttsNumber,
    this.paymentTypeName,
    required this.amount,
    this.ttsDate,
    required this.paymentStatus,
    required this.paymentLabel,
  });

  @override
  List<Object?> get props => [
    ttsNumber,
    paymentTypeName,
    amount,
    ttsDate,
    paymentStatus,
    paymentLabel,
  ];
}

/// Satu langkah timeline (10 tahap) — hasil `ReserveOrderService::buildTimeline`.
class ReserveOrderTimelineStepEntity extends Equatable {
  final String code;
  final String label;
  final String? sub;
  final ReserveOrderStageStatus status;
  final ReserveOrderTimelineMessageEntity? latestMessage;

  /// Nama status Batal (mis. "SP Batal") kalau order dibatalkan di tahap ini, null kalau tidak.
  final String? cancelLabel;

  /// Rincian TTS tahap ini (Reserve / RB / SP), kosong di tahap lain.
  final List<ReserveOrderTimelineTtsEntity> tts;

  const ReserveOrderTimelineStepEntity({
    required this.code,
    required this.label,
    this.sub,
    required this.status,
    this.latestMessage,
    this.cancelLabel,
    this.tts = const [],
  });

  @override
  List<Object?> get props => [
    code,
    label,
    sub,
    status,
    latestMessage,
    cancelLabel,
    tts,
  ];
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

  /// Deskripsi yang diisi saat upload (`attachment_note`).
  final String? attachmentNote;
  final DateTime? createDatetime;

  /// Dokumen ini punya status verifikasi? (`is_verifiable`) — hanya KTP Pemohon & Bukti Transfer.
  /// Dokumen lain tampil tanpa status (Menunggu verifikasi/Disetujui/Ditolak).
  final bool isVerifiable;

  /// `locked` — dokumen customer (KTP, NPWP, KK, dst — dipakai bersama semua RO customer) & salah satu
  /// RO customer ini sudah Akad: Upload Ulang / Hapus disable (alasan: `doc_locked_reason` detail).
  /// Bukti Transfer / dokumen TTS selalu false.
  final bool locked;

  const ReserveOrderAttachmentEntity({
    required this.contactAttachmentId,
    this.attachmentTypeId,
    this.attachmentPath,
    this.reserveOrderTtsId,
    this.verificationStatus,
    this.verificationNote,
    this.attachmentNote,
    this.createDatetime,
    this.isVerifiable = true,
    this.locked = false,
  });

  bool get isRejected => isVerifiable && verificationStatus == 'rejected';

  @override
  List<Object?> get props => [
    contactAttachmentId,
    attachmentTypeId,
    attachmentPath,
    reserveOrderTtsId,
    verificationStatus,
    verificationNote,
    attachmentNote,
    createDatetime,
    isVerifiable,
    locked,
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

  /// Lampiran opsional (link Google Drive) + nama file aslinya.
  final String? attachmentUrl;
  final String? attachmentName;

  /// Info dari form Tulis Pesan (web) — pesan lama/log sistem: [contactedBy] & [followUp] kosong.
  final String? customer;
  final String? contactedBy;
  final String? status;
  final String? followUp;

  const ReserveOrderMessageEntity({
    required this.who,
    this.isMe = false,
    this.time,
    required this.text,
    this.attachmentUrl,
    this.attachmentName,
    this.customer,
    this.contactedBy,
    this.status,
    this.followUp,
  });

  @override
  List<Object?> get props => [
    who,
    isMe,
    time,
    text,
    attachmentUrl,
    attachmentName,
    customer,
    contactedBy,
    status,
    followUp,
  ];
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

/// Satu pembayaran TTS yang bisa diajukan ulang (`resubmit.tts.items[]`).
class ReserveOrderResubmitPaymentEntity extends Equatable {
  /// Nilai DB apa adanya: `Tunai` / `Transfer` / `Kartu Kredit` / `Giro`.
  final String paymentMethod;
  final double amount;
  final int? bankId;
  final String? bankName;
  final String? cardNetwork;
  final String? referenceNumber;
  final DateTime? referenceDate;

  /// `tunai_deposited` — Tunai ini sudah disetor ke bank: tidak boleh dihapus / diubah nominalnya.
  final bool tunaiDeposited;

  const ReserveOrderResubmitPaymentEntity({
    required this.paymentMethod,
    this.amount = 0,
    this.bankId,
    this.bankName,
    this.cardNetwork,
    this.referenceNumber,
    this.referenceDate,
    this.tunaiDeposited = false,
  });

  @override
  List<Object?> get props => [
    paymentMethod,
    amount,
    bankId,
    bankName,
    cardNetwork,
    referenceNumber,
    referenceDate,
    tunaiDeposited,
  ];
}

/// Bukti pembayaran lama TTS (`resubmit.tts.proofs[]`) — dihapus lewat `tts[delete_proof_ids][]`.
class ReserveOrderResubmitProofEntity extends Equatable {
  final int contactAttachmentId;
  final String? attachmentPath;
  final String? verificationStatus;

  const ReserveOrderResubmitProofEntity({
    required this.contactAttachmentId,
    this.attachmentPath,
    this.verificationStatus,
  });

  @override
  List<Object?> get props => [
    contactAttachmentId,
    attachmentPath,
    verificationStatus,
  ];
}

/// TTS order yang diajukan ulang (`resubmit.tts`). [editable] false = sudah disetujui Kasir
/// (biasanya kasus tolak SA) → tampil read-only dgn [lockedReason] & `tts[...]` tidak dikirim.
class ReserveOrderResubmitTtsEntity extends Equatable {
  final int reserveOrderTtsId;
  final String ttsNumber;
  final int? paymentTypeId;
  final bool editable;
  final String? lockedReason;
  final List<ReserveOrderResubmitPaymentEntity> items;
  final List<ReserveOrderResubmitProofEntity> proofs;

  const ReserveOrderResubmitTtsEntity({
    required this.reserveOrderTtsId,
    this.ttsNumber = '',
    this.paymentTypeId,
    this.editable = false,
    this.lockedReason,
    this.items = const [],
    this.proofs = const [],
  });

  @override
  List<Object?> get props => [
    reserveOrderTtsId,
    ttsNumber,
    paymentTypeId,
    editable,
    lockedReason,
    items,
    proofs,
  ];
}

/// Data prefill wizard "Pengajuan Ulang" (`resubmit`) — null kalau `can_resubmit` false.
class ReserveOrderResubmitEntity extends Equatable {
  final DateTime? reserveDate;

  /// false = order sudah di-approve Kasir, unit hanya bisa diganti SA (alasan: [unitLockedReason]).
  final bool unitEditable;
  final String? unitLockedReason;

  /// null = order tanpa TTS.
  final ReserveOrderResubmitTtsEntity? tts;

  const ReserveOrderResubmitEntity({
    this.reserveDate,
    this.unitEditable = false,
    this.unitLockedReason,
    this.tts,
  });

  @override
  List<Object?> get props => [reserveDate, unitEditable, unitLockedReason, tts];
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

  /// `township_id` project unit — Ganti Unit dikunci di project ini.
  final int? townshipId;
  final String? caraBayarName;
  final bool canTopup;

  /// `can_change_unit` — Ganti Unit boleh selama order belum di-approve Kasir (sesudahnya unit
  /// diganti Sales Admin), sama dgn Ganti Unit Kasir di web.
  final bool canChangeUnit;

  /// `topup_locked_reason` — terisi kalau order sudah SP / Akad: tombol "+ Top Up Pembayaran" tampil
  /// disable dengan alasan ini (bukan disembunyikan seperti order Ditolak/Batal).
  final String? topupLockedReason;

  /// `edit_locked_reason` — terisi kalau order sudah Akad/PPJB: SEMUA edit dikunci (banner di header;
  /// `can_edit`/`can_delete` ikut false dari backend, upload/hapus dokumen juga disembunyikan).
  final String? editLockedReason;

  /// `doc_locked_reason` — terisi kalau salah satu RO customer ini sudah Akad: dokumen customer
  /// (`attachments[].locked`) tidak bisa diganti/dihapus, tambah dokumen tetap boleh (RO belum Akad).
  final String? docLockedReason;

  /// `delete_locked_reason` — terisi kalau order sudah Akad / sudah diverifikasi Kasir: menu
  /// "Delete Reserve Order" tampil disable dengan alasan ini (`can_delete` ikut false).
  final String? deleteLockedReason;

  /// Flag kapabilitas per-record dari backend (`can_edit`/`can_delete`, scope Own/Team/Any form
  /// "Reserve Order"). Hanya untuk UX (sembunyikan tombol) — enforcement tetap di server.
  final bool canEdit;
  final bool canDelete;
  final String? statusLabel;
  final bool isRejected;
  final String? rejectStage;
  final String? rejectReason;

  /// `reject_source` — yang menolak: `kasir` / `sales_admin` (null = tidak sedang ditolak).
  final String? rejectSource;

  /// `can_resubmit` — Ditolak, user boleh Modify & belum Akad → tombol "Pengajuan Ulang".
  /// null = backend lama belum kirim field ini (app fallback ke `isRejected && canEdit`).
  final bool? canResubmit;
  final ReserveOrderResubmitEntity? resubmit;
  final List<ReserveOrderTimelineStepEntity> timeline;

  /// Row `m_customer_reserve` apa adanya (cocok langsung dgn `ReserveOrderCustomerData.raw`).
  final Map<String, dynamic> customer;

  /// Kuesioner customer (null = order tanpa customer / backend lama).
  final ReserveQuestionnaireEntity? questionnaire;
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
    this.townshipId,
    this.caraBayarName,
    this.canTopup = false,
    this.canChangeUnit = false,
    this.topupLockedReason,
    this.editLockedReason,
    this.docLockedReason,
    this.deleteLockedReason,
    this.canEdit = true,
    this.canDelete = true,
    this.statusLabel,
    this.isRejected = false,
    this.rejectStage,
    this.rejectReason,
    this.rejectSource,
    this.canResubmit,
    this.resubmit,
    this.timeline = const [],
    this.customer = const {},
    this.questionnaire,
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
    townshipId,
    caraBayarName,
    reserveNote,
    caraBayarId,
    propertyId,
    productId,
    companyId,
    canTopup,
    canChangeUnit,
    topupLockedReason,
    editLockedReason,
    docLockedReason,
    deleteLockedReason,
    canEdit,
    canDelete,
    statusLabel,
    isRejected,
    rejectStage,
    rejectReason,
    rejectSource,
    canResubmit,
    resubmit,
    timeline,
    customer,
    questionnaire,
    requiredDocs,
    attachments,
    ttsList,
    totalPaidSoFar,
    messages,
    sales,
  ];
}
