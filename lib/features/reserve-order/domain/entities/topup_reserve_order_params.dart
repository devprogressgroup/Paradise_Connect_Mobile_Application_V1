import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Payload untuk `POST /reserve-order/topup/{reserveOrderId}` (`ReserveOrderController::topup`).
class TopupReserveOrderParams extends Equatable {
  final int? paymentTypeId;
  final String? ttsType;
  final String? note;
  final List<TopupReserveOrderPaymentParams> payments;

  const TopupReserveOrderParams({
    this.paymentTypeId,
    this.ttsType,
    this.note,
    required this.payments,
  });

  @override
  List<Object?> get props => [paymentTypeId, ttsType, note, payments];
}

class TopupReserveOrderPaymentParams extends Equatable {
  /// 'cash' atau 'transfer' — dinormalisasi ke enum DB ('Tunai'/'Transfer') di backend, sama
  /// seperti `CreateReserveOrderPaymentParams.paymentMethod`.
  final String paymentMethod;
  final double amount;
  final int? bankId;
  final String? bankName;
  final String? cardNetwork;
  final String? referenceNumber;
  final DateTime? referenceDate;
  final Uint8List? proofBytes;
  final String? proofFileName;

  const TopupReserveOrderPaymentParams({
    required this.paymentMethod,
    required this.amount,
    this.bankId,
    this.bankName,
    this.cardNetwork,
    this.referenceNumber,
    this.referenceDate,
    this.proofBytes,
    this.proofFileName,
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
    proofBytes,
    proofFileName,
  ];
}
