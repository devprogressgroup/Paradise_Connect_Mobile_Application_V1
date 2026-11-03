import 'package:equatable/equatable.dart';

import 'create_reserve_order_params.dart' show CreateReserveOrderFile;

/// Payload untuk `POST /reserve-order/update/{reserveOrderId}`
/// (`ReserveOrderController::update` — "Perbaiki Data Customer").
class UpdateReserveOrderCustomerParams extends Equatable {
  final Map<String, dynamic>? customer;
  final CreateReserveOrderFile? ktp;
  final CreateReserveOrderFile? npwp;

  /// Jawaban kuesioner `questioner[<name>]` (null = jawaban kosong), disimpan di request yang sama
  /// — halaman Edit Data Customer memuat kuesioner, jadi 1x Save. null = kuesioner tidak dikirim
  /// (jawaban lama tidak disentuh).
  final Map<String, String?>? questioner;

  const UpdateReserveOrderCustomerParams({
    this.customer,
    this.ktp,
    this.npwp,
    this.questioner,
  });

  @override
  List<Object?> get props => [customer, ktp, npwp, questioner];
}
