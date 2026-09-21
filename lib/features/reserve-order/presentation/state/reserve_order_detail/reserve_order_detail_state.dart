import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_detail_entity.dart';

enum ReserveOrderDetailStatus { initial, loading, loaded, mutating, error }

class ReserveOrderDetailState extends Equatable {
  final ReserveOrderDetailStatus status;
  final ReserveOrderDetailEntity? detail;
  final String? errorMessage;

  const ReserveOrderDetailState({
    this.status = ReserveOrderDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  ReserveOrderDetailState copyWith({
    ReserveOrderDetailStatus? status,
    ReserveOrderDetailEntity? detail,
    String? errorMessage,
  }) {
    return ReserveOrderDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
