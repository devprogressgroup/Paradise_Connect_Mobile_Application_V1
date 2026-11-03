import 'package:equatable/equatable.dart';

/// Payload `POST /reserve-order/unit/{reserveOrderId}` (`ReserveOrderController::changeUnit`) — kavling
/// tujuan ([propertyId]) ATAU tanpa kavling ([unitMode]: `waiting` = Waitinglist, `undecided` = Belum
/// menentukan kavling), plus tipe & project-nya. Divalidasi server sama dgn Ganti Unit Kasir web.
class ChangeReserveOrderUnitParams extends Equatable {
  final int? propertyId;
  final String? unitMode;
  final int productId;
  final int townshipId;
  final int companyId;

  const ChangeReserveOrderUnitParams({
    this.propertyId,
    this.unitMode,
    required this.productId,
    required this.townshipId,
    required this.companyId,
  });

  @override
  List<Object?> get props => [
    propertyId,
    unitMode,
    productId,
    townshipId,
    companyId,
  ];
}
