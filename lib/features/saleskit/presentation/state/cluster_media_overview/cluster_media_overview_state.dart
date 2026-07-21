import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';
import 'media_group_section.dart';

abstract class ClusterMediaOverviewState {}

class ClusterMediaOverviewInitial extends ClusterMediaOverviewState {}

class ClusterMediaOverviewLoading extends ClusterMediaOverviewState {}

class ClusterMediaOverviewLoaded extends ClusterMediaOverviewState {
  final int clusterId;
  final MediaOwnerType ownerType;
  final List<MediaGroupSection> sections;
  ClusterMediaOverviewLoaded({required this.clusterId, required this.ownerType, required this.sections});
}

class ClusterMediaOverviewError extends ClusterMediaOverviewState {
  final String message;
  ClusterMediaOverviewError(this.message);
}
