import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Payload untuk `POST /reserve-order/create` (`ReserveOrderController::store`). Bentuknya
/// sengaja mengikuti persis struktur body yang divalidasi backend (`customer`, `documents`,
/// `units[].payments[]`) supaya gampang ditelusuri dari kedua sisi.
class CreateReserveOrderParams extends Equatable {
  final int contactId;
  final String? reserveNote;

  /// Field-field `m_customer_reserve` yang dikirim, sudah pakai key snake_case persis nama
  /// kolom backend (mis. `cust_name`, `cust_ktp`, `cara_bayar_id`).
  final Map<String, dynamic> customer;

  final CreateReserveOrderFile? ktp;
  final CreateReserveOrderFile? npwp;

  /// Hirarki sales milik Contact (dari `ContactEntity` — lihat `reserve_order_navigation.dart`).
  /// Kalau null, backend fallback resolve dari sales_person user yang login.
  final int? salesExecutiveId;
  final int? salesSupervisorId;
  final int? salesManagerId;
  final int? salesGeneralManagerId;
  final int? salesTeamId;

  final List<CreateReserveOrderUnitParams> units;

  const CreateReserveOrderParams({
    required this.contactId,
    this.reserveNote,
    required this.customer,
    this.ktp,
    this.npwp,
    this.salesExecutiveId,
    this.salesSupervisorId,
    this.salesManagerId,
    this.salesGeneralManagerId,
    this.salesTeamId,
    required this.units,
  });

  @override
  List<Object?> get props => [
        contactId,
        reserveNote,
        customer,
        ktp,
        npwp,
        salesExecutiveId,
        salesSupervisorId,
        salesManagerId,
        salesGeneralManagerId,
        salesTeamId,
        units,
      ];
}

/// Satu slot dokumen — file baru (`bytes`) ATAU reuse lampiran lama (`existingAttachmentId`,
/// mis. KTP yang sudah ada di data Contact) TANPA upload ulang.
class CreateReserveOrderFile extends Equatable {
  final Uint8List? bytes;
  final String? fileName;
  final int? existingAttachmentId;

  const CreateReserveOrderFile({
    this.bytes,
    this.fileName,
    this.existingAttachmentId,
  });

  bool get isEmpty => bytes == null && existingAttachmentId == null;

  @override
  List<Object?> get props => [bytes, fileName, existingAttachmentId];
}

class CreateReserveOrderUnitParams extends Equatable {
  final int? dealId;
  final int? companyId;
  final int? productId;
  final int? propertyId;
  final String? propertyName;
  final String? paymentType;
  final int? paymentTypeId;
  final String? note;
  final List<CreateReserveOrderPaymentParams> payments;

  const CreateReserveOrderUnitParams({
    this.dealId,
    this.companyId,
    this.productId,
    this.propertyId,
    this.propertyName,
    this.paymentType,
    this.paymentTypeId,
    this.note,
    required this.payments,
  });

  @override
  List<Object?> get props => [
        dealId,
        companyId,
        productId,
        propertyId,
        propertyName,
        paymentType,
        paymentTypeId,
        note,
        payments,
      ];
}

class CreateReserveOrderPaymentParams extends Equatable {
  /// 'cash' atau 'transfer' — dinormalisasi ke enum DB ('Tunai'/'Transfer') di backend.
  final String paymentMethod;
  final double amount;
  final Uint8List? proofBytes;
  final String? proofFileName;
  final String? bankName;
  final String? referenceNumber;

  const CreateReserveOrderPaymentParams({
    required this.paymentMethod,
    required this.amount,
    this.proofBytes,
    this.proofFileName,
    this.bankName,
    this.referenceNumber,
  });

  @override
  List<Object?> get props => [
        paymentMethod,
        amount,
        proofBytes,
        proofFileName,
        bankName,
        referenceNumber,
      ];
}
