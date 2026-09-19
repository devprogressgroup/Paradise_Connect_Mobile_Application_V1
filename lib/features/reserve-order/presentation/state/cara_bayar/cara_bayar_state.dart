import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';

enum CaraBayarStatus { initial, loading, loaded, error }

class CaraBayarState extends Equatable {
  final CaraBayarStatus status;
  final List<CaraBayarEntity> items;
  final String? errorMessage;

  const CaraBayarState({
    this.status = CaraBayarStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  CaraBayarState copyWith({
    CaraBayarStatus? status,
    List<CaraBayarEntity>? items,
    String? errorMessage,
  }) {
    return CaraBayarState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
