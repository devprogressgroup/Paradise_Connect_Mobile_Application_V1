import 'package:equatable/equatable.dart';

class PropertyUnitItem {
  final int id;
  final String name;

  const PropertyUnitItem({required this.id, required this.name});
}

class PropertyUnitCluster extends Equatable {
  final int clusterId;
  final String clusterName;
  final List<PropertyUnitItem> units;

  const PropertyUnitCluster({
    required this.clusterId,
    required this.clusterName,
    required this.units,
  });

  @override
  List<Object?> get props => [clusterId, clusterName];
}
