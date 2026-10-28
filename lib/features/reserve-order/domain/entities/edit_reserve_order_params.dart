import 'package:equatable/equatable.dart';

/// Payload untuk `POST /reserve-order/edit/{reserveOrderId}` (`ReserveOrderController::edit`) —
/// field level order (cara bayar, catatan), DI LUAR data customer (`update`), pembayaran/TTS
/// (`topup`), dan unit (`unit`, lihat [ChangeReserveOrderUnitParams]).
class EditReserveOrderParams extends Equatable {
  final String? reserveNote;
  final int? caraBayarId;

  const EditReserveOrderParams({this.reserveNote, this.caraBayarId});

  @override
  List<Object?> get props => [reserveNote, caraBayarId];
}
