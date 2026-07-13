import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';

class InfoSourceModel extends InfoSource {
  const InfoSourceModel({
    required super.id,
    required super.name,
    required super.typeData,
    super.periodePameranId,
    super.isPameran,
  });

  factory InfoSourceModel.fromJson(Map<String, dynamic> json) {
    return InfoSourceModel(
      id: json['master_data_id'] as int,
      name: json['name'] as String,
      typeData: json['type_data'] as String,
      periodePameranId: json['periode_pameran_id'] as int?,
      isPameran: json['is_pameran'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master_data_id': id,
      'name': name,
      'type_data': typeData,
      if (periodePameranId != null) 'periode_pameran_id': periodePameranId,
      'is_pameran': isPameran,
    };
  }
}