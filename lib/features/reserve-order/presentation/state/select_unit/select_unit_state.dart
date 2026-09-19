import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';

enum SelectUnitStatus { initial, loading, loaded, error }

class SelectUnitState extends Equatable {
  final SelectUnitStatus status;
  final List<SelectUnitEntity> items;
  final String? errorMessage;

  const SelectUnitState({
    this.status = SelectUnitStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  SelectUnitState copyWith({
    SelectUnitStatus? status,
    List<SelectUnitEntity>? items,
    String? errorMessage,
  }) {
    return SelectUnitState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
