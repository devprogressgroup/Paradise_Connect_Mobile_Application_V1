import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/change_reserve_order_unit_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';

/// Payload `POST /reserve-order/resubmit/{id}` — wizard Create Reserve Order mode "Pengajuan Ulang"
/// (order Ditolak Kasir / Sales Admin). Key [customer] & dokumen SAMA dgn `POST /reserve-order/create`
/// ([CreateReserveOrderParams]).
class ResubmitReserveOrderParams extends Equatable {
  final Map<String, dynamic> customer;
  final String? reserveNote;
  final DateTime? reserveDate;

  /// null = tidak dikirim → dokumen lama tetap dipakai.
  final CreateReserveOrderFile? ktp;
  final CreateReserveOrderFile? npwp;

  /// `unit[...]` — bentuknya sama dgn Ganti Unit. null = tidak dikirim (unit sekarang tetap).
  final ChangeReserveOrderUnitParams? unit;

  /// `tts[...]` — null kalau TTS tidak diedit (order tanpa TTS / TTS sudah disetujui Kasir).
  final ResubmitReserveOrderTtsParams? tts;

  const ResubmitReserveOrderParams({
    required this.customer,
    this.reserveNote,
    this.reserveDate,
    this.ktp,
    this.npwp,
    this.unit,
    this.tts,
  });

  @override
  List<Object?> get props => [
    customer,
    reserveNote,
    reserveDate,
    ktp,
    npwp,
    unit,
    tts,
  ];
}

/// `tts[...]` — pembayaran formatnya sama dgn create/top up ([TopupReserveOrderPaymentParams]).
class ResubmitReserveOrderTtsParams extends Equatable {
  final int reserveOrderTtsId;
  final int? paymentTypeId;
  final List<TopupReserveOrderPaymentParams> payments;

  /// `contact_attachment_id` bukti lama yang dihapus.
  final List<int> deleteProofIds;

  const ResubmitReserveOrderTtsParams({
    required this.reserveOrderTtsId,
    this.paymentTypeId,
    required this.payments,
    this.deleteProofIds = const [],
  });

  @override
  List<Object?> get props => [
    reserveOrderTtsId,
    paymentTypeId,
    payments,
    deleteProofIds,
  ];
}
