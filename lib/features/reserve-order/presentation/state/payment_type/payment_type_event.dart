import 'package:equatable/equatable.dart';

abstract class PaymentTypeEvent extends Equatable {
  const PaymentTypeEvent();

  @override
  List<Object?> get props => [];
}

class FetchPaymentTypesEvent extends PaymentTypeEvent {
  const FetchPaymentTypesEvent();
}
