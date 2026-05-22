import 'package:progress_group/features/contact/domain/entities/property/property_unit_entity.dart';

class PropertyUnitItemModel extends PropertyUnitItem {
  const PropertyUnitItemModel({required super.id, required super.name});

  factory PropertyUnitItemModel.fromJson(Map<String, dynamic> json) =>
      PropertyUnitItemModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
      );
}

class PropertyUnitClusterModel extends PropertyUnitCluster {
  const PropertyUnitClusterModel({
    required super.clusterId,
    required super.clusterName,
    required super.units,
  });

  factory PropertyUnitClusterModel.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>? ?? [])
        .map((u) => PropertyUnitItemModel.fromJson(u as Map<String, dynamic>))
        .toList();
    return PropertyUnitClusterModel(
      clusterId: json['cluster_id'] as int? ?? 0,
      clusterName: json['cluster_name'] as String? ?? '',
      units: units,
    );
  }

  factory PropertyUnitClusterModel.fromCommercialJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>? ?? [])
        .map((u) => PropertyUnitItemModel.fromJson(u as Map<String, dynamic>))
        .toList();
    return PropertyUnitClusterModel(
      clusterId: json['commercial_id'] as int? ?? 0,
      clusterName: json['commercial_name'] as String? ?? '',
      units: units,
    );
  }
}
