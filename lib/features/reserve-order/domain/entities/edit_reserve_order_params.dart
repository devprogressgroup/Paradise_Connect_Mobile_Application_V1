import 'package:equatable/equatable.dart';

/// Payload untuk `POST /reserve-order/edit/{reserveOrderId}` (`ReserveOrderController::edit`) —
/// field level order (unit/produk, cara bayar, catatan), DI LUAR data customer (`update`) dan
/// pembayaran/TTS (`topup`).
class EditReserveOrderParams extends Equatable {
  final String? reserveNote;
  final int? caraBayarId;
  final int? propertyId;
  final int? productId;
  final int? companyId;
  final String? propertyName;

  const EditReserveOrderParams({
    this.reserveNote,
    this.caraBayarId,
    this.propertyId,
    this.productId,
    this.companyId,
    this.propertyName,
  });

  @override
  List<Object?> get props => [
    reserveNote,
    caraBayarId,
    propertyId,
    productId,
    companyId,
    propertyName,
  ];
}
