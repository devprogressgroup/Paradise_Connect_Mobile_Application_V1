import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

class ClusterMediaListArgs {
  final int clusterId;
  final MediaOwnerType ownerType;
  final int mediaGroupId;
  final String groupName;
  final String propertyTitle;

  const ClusterMediaListArgs({
    required this.clusterId,
    this.ownerType = MediaOwnerType.cluster,
    required this.mediaGroupId,
    required this.groupName,
    required this.propertyTitle,
  });
}
