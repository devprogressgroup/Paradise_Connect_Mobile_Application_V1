import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_result_entity.dart';

abstract class CreateReserveOrderState extends Equatable {
  const CreateReserveOrderState();

  @override
  List<Object?> get props => [];
}

class CreateReserveOrderInitial extends CreateReserveOrderState {
  const CreateReserveOrderInitial();
}

class CreateReserveOrderSubmitting extends CreateReserveOrderState {
  const CreateReserveOrderSubmitting();
}

class CreateReserveOrderSuccess extends CreateReserveOrderState {
  final CreateReserveOrderResultEntity result;

  const CreateReserveOrderSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class CreateReserveOrderError extends CreateReserveOrderState {
  final String message;

  const CreateReserveOrderError(this.message);

  @override
  List<Object?> get props => [message];
}
