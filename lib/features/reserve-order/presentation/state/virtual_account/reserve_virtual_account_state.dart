import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';

enum UnitVirtualAccountStatus {
  /// Request `GET /property/virtual-account` masih jalan.
  loading,

  /// Unit tanpa `property_id` (Waitinglist / Belum menentukan kavling) — endpoint tidak dipanggil.
  noKavling,

  /// Sukses — [UnitVirtualAccountState.accounts] bisa kosong.
  loaded,

  /// 404 `VA_NOT_FOUND` — unit ada tapi belum punya VA.
  notFound,

  /// Error lain / timeout / data unit tidak lengkap.
  failed,
}

class UnitVirtualAccountState extends Equatable {
  final UnitVirtualAccountStatus status;
  final List<VirtualAccountEntity> accounts;

  const UnitVirtualAccountState(this.status, {this.accounts = const []});

  @override
  List<Object?> get props => [status, accounts];
}

class ReserveVirtualAccountState extends Equatable {
  /// Status VA per unit — key = `VirtualAccountLookup.unitKey` (id unit di wizard).
  final Map<String, UnitVirtualAccountState> units;

  const ReserveVirtualAccountState({this.units = const {}});

  @override
  List<Object?> get props => [units];
}
