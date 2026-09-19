import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';

enum ReserveStatusEnum { initial, loading, loaded, error }

class ReserveStatusState extends Equatable {
  final ReserveStatusEnum status;
  final List<ReserveStatusEntity> statuses;
  final String? errorMessage;

  const ReserveStatusState({
    this.status = ReserveStatusEnum.initial,
    this.statuses = const [],
    this.errorMessage,
  });

  ReserveStatusState copyWith({
    ReserveStatusEnum? status,
    List<ReserveStatusEntity>? statuses,
    String? errorMessage,
  }) {
    return ReserveStatusState(
      status: status ?? this.status,
      statuses: statuses ?? this.statuses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, statuses, errorMessage];
}
