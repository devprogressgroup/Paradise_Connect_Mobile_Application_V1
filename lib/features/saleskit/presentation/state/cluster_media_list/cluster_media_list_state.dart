import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

abstract class ClusterMediaListState {}

class ClusterMediaListInitial extends ClusterMediaListState {}

class ClusterMediaListLoading extends ClusterMediaListState {}

class ClusterMediaListLoaded extends ClusterMediaListState {
  final int clusterId;
  final MediaOwnerType ownerType;
  final int mediaGroupId;
  final String? search;
  final String sortBy;
  final String sortDir;
  final List<MediaItemEntity> items;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  ClusterMediaListLoaded({
    required this.clusterId,
    required this.ownerType,
    required this.mediaGroupId,
    this.search,
    required this.sortBy,
    required this.sortDir,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ClusterMediaListLoaded copyWith({
    List<MediaItemEntity>? items,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return ClusterMediaListLoaded(
      clusterId: clusterId,
      ownerType: ownerType,
      mediaGroupId: mediaGroupId,
      search: search,
      sortBy: sortBy,
      sortDir: sortDir,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ClusterMediaListError extends ClusterMediaListState {
  final String message;
  ClusterMediaListError(this.message);
}
