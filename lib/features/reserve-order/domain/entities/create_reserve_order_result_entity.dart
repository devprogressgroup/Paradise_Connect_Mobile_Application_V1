import 'package:equatable/equatable.dart';

/// Hasil `POST /reserve-order/create` — ringkasan customer + reserve order (dan TTS-nya, 1 per
/// unit) yang berhasil dibuat, dipakai buat ditampilkan di step Success wizard.
class CreateReserveOrderResultEntity extends Equatable {
  final int customerId;
  final String custName;
  final List<CreateReserveOrderItemEntity> orders;

  const CreateReserveOrderResultEntity({
    required this.customerId,
    required this.custName,
    required this.orders,
  });

  @override
  List<Object?> get props => [customerId, custName, orders];
}

class CreateReserveOrderItemEntity extends Equatable {
  final int reserveOrderId;
  final String? propertyName;
  final int? statusReserveId;
  final int reserveOrderTtsId;
  final String ttsNumber;
  final double ttsAmountRp;

  const CreateReserveOrderItemEntity({
    required this.reserveOrderId,
    this.propertyName,
    this.statusReserveId,
    required this.reserveOrderTtsId,
    required this.ttsNumber,
    required this.ttsAmountRp,
  });

  @override
  List<Object?> get props => [
        reserveOrderId,
        propertyName,
        statusReserveId,
        reserveOrderTtsId,
        ttsNumber,
        ttsAmountRp,
      ];
}
