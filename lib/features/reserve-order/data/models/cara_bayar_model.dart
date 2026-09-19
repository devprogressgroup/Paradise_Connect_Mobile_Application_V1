import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';

class CaraBayarModel extends CaraBayarEntity {
  const CaraBayarModel({required super.caraBayarId, required super.name});

  factory CaraBayarModel.fromJson(Map<String, dynamic> json) {
    return CaraBayarModel(
      caraBayarId: json['cara_bayar_id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
