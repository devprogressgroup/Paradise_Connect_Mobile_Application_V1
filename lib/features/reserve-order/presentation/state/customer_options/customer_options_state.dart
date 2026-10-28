import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';

enum CustomerOptionsStatus { initial, loading, loaded, error }

class CustomerOptionsState extends Equatable {
  final CustomerOptionsStatus status;
  final CustomerOptionsEntity options;
  final String? errorMessage;

  const CustomerOptionsState({
    this.status = CustomerOptionsStatus.initial,
    this.options = const CustomerOptionsEntity(),
    this.errorMessage,
  });

  CustomerOptionsState copyWith({
    CustomerOptionsStatus? status,
    CustomerOptionsEntity? options,
    String? errorMessage,
  }) {
    return CustomerOptionsState(
      status: status ?? this.status,
      options: options ?? this.options,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, options, errorMessage];
}
