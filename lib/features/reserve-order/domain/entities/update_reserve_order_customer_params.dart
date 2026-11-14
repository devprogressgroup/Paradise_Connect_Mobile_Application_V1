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

  /// Data awal customer (`widget.customer.raw`) — dipakai untuk membandingkan field terkunci.
  final Map<String, dynamic>? originalCustomer;

  /// true = order sudah SP (`ktp_locked_reason` terisi): field KTP/pekerjaan terkunci yang nilainya
  /// SAMA dgn [originalCustomer] tidak ikut dikirim (datasource yang menyaring).
  final bool ktpLocked;

  const UpdateReserveOrderCustomerParams({
    this.customer,
    this.ktp,
    this.npwp,
    this.questioner,
    this.originalCustomer,
    this.ktpLocked = false,
  });

  @override
  List<Object?> get props => [
    customer,
    ktp,
    npwp,
    questioner,
    originalCustomer,
    ktpLocked,
  ];
}

/// Gagal "Perbaiki Data Customer". [errorCode] = `error_code` body (`KTP_LOCKED` = ada field KTP/
/// pekerjaan yang terkunci & berubah; [lockedFields] = key `customer[...]` yang ditolak server).
/// Kosong kalau gagal jaringan / error lain.
class ReserveOrderCustomerFailure extends Equatable {
  final String message;
  final String? errorCode;
  final List<String> lockedFields;

  const ReserveOrderCustomerFailure(
    this.message, {
    this.errorCode,
    this.lockedFields = const [],
  });

  bool get isKtpLocked => errorCode == 'KTP_LOCKED';

  @override
  List<Object?> get props => [message, errorCode, lockedFields];
}
