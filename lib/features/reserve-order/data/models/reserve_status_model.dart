import 'package:progress_group/features/reserve-order/domain/entities/reserve_status_entity.dart';

class ReserveStatusModel extends ReserveStatusEntity {
  const ReserveStatusModel({
    required super.statusReserveId,
    required super.statusReserveName,
    required super.displayName,
  });

  factory ReserveStatusModel.fromJson(Map<String, dynamic> json) {
    final name = json['status_reserve_name'] as String? ?? '';
    return ReserveStatusModel(
      statusReserveId: json['status_reserve_id'] as int,
      statusReserveName: name,
      displayName: (json['display_name'] as String?)?.isNotEmpty == true
          ? json['display_name'] as String
          : name,
    );
  }
}
