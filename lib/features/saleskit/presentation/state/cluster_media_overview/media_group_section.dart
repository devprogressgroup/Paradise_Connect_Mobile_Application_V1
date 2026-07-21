import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

class MediaGroupSection {
  final int mediaGroupId;
  final String groupName;
  final List<MediaItemEntity> items;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  const MediaGroupSection({
    required this.mediaGroupId,
    required this.groupName,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  MediaGroupSection copyWith({
    List<MediaItemEntity>? items,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return MediaGroupSection(
      mediaGroupId: mediaGroupId,
      groupName: groupName,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
