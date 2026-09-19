import 'package:equatable/equatable.dart';

class PaymentTypeEntity extends Equatable {
  final int paymentTypeId;
  final String name;

  const PaymentTypeEntity({required this.paymentTypeId, required this.name});

  @override
  List<Object?> get props => [paymentTypeId, name];
}
