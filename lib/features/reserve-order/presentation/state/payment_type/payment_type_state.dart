import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';

enum PaymentTypeStatus { initial, loading, loaded, error }

class PaymentTypeState extends Equatable {
  final PaymentTypeStatus status;
  final List<PaymentTypeEntity> items;
  final String? errorMessage;

  const PaymentTypeState({
    this.status = PaymentTypeStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  PaymentTypeState copyWith({
    PaymentTypeStatus? status,
    List<PaymentTypeEntity>? items,
    String? errorMessage,
  }) {
    return PaymentTypeState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
