import 'package:equatable/equatable.dart';

import 'create_reserve_order_params.dart' show CreateReserveOrderFile;

/// Payload untuk `POST /reserve-order/update/{reserveOrderId}`
/// (`ReserveOrderController::update` — "Perbaiki Data Customer").
class UpdateReserveOrderCustomerParams extends Equatable {
  final Map<String, dynamic>? customer;
  final CreateReserveOrderFile? ktp;
  final CreateReserveOrderFile? npwp;

  const UpdateReserveOrderCustomerParams({this.customer, this.ktp, this.npwp});

  @override
  List<Object?> get props => [customer, ktp, npwp];
}
