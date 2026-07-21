import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

abstract class ClusterMediaOverviewEvent {}

class LoadClusterMediaOverviewEvent extends ClusterMediaOverviewEvent {
  final int clusterId;
  final MediaOwnerType ownerType;
  LoadClusterMediaOverviewEvent(this.clusterId, {this.ownerType = MediaOwnerType.cluster});
}

class LoadMoreGroupMediaEvent extends ClusterMediaOverviewEvent {
  final int clusterId;
  final MediaOwnerType ownerType;
  final int mediaGroupId;
  LoadMoreGroupMediaEvent({
    required this.clusterId,
    this.ownerType = MediaOwnerType.cluster,
    required this.mediaGroupId,
  });
}
