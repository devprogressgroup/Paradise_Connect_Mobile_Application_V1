import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

abstract class ClusterMediaListEvent {}

class LoadClusterMediaListEvent extends ClusterMediaListEvent {
  final int clusterId;
  final MediaOwnerType ownerType;
  final int mediaGroupId;
  final String? search;
  final String sortBy;
  final String sortDir;

  LoadClusterMediaListEvent({
    required this.clusterId,
    this.ownerType = MediaOwnerType.cluster,
    required this.mediaGroupId,
    this.search,
    this.sortBy = 'created_at',
    this.sortDir = 'desc',
  });
}

class LoadMoreClusterMediaListEvent extends ClusterMediaListEvent {}
