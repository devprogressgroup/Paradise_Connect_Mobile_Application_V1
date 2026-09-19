import 'package:progress_group/features/reserve-order/domain/entities/payment_type_entity.dart';

class PaymentTypeModel extends PaymentTypeEntity {
  const PaymentTypeModel({required super.paymentTypeId, required super.name});

  factory PaymentTypeModel.fromJson(Map<String, dynamic> json) {
    return PaymentTypeModel(
      paymentTypeId: json['payment_type_id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
