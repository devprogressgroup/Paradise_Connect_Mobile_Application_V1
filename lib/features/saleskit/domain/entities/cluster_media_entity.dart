enum MediaOwnerType {
  cluster,
  commercial;

  String get pathSegment => this == MediaOwnerType.commercial ? 'commercials' : 'clusters';
}

class MediaCaptionEntity {
  final int captionId;
  final String name;
  final int shareCount;
  final int shareTotal;
  final String? shareDatetime;

  const MediaCaptionEntity({
    required this.captionId,
    required this.name,
    required this.shareCount,
    required this.shareTotal,
    this.shareDatetime,
  });
}

class MediaItemEntity {
  final int mediaId;
  final String name;
  final String? thumbnail;
  final String? link;
  final List<MediaCaptionEntity> captions;
  final int mediaGroupId;
  final String groupName;

  const MediaItemEntity({
    required this.mediaId,
    required this.name,
    this.thumbnail,
    this.link,
    this.captions = const [],
    required this.mediaGroupId,
    required this.groupName,
  });
}

class MediaPaginationEntity {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const MediaPaginationEntity({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class ClusterMediaPageEntity {
  final List<MediaItemEntity> items;
  final MediaPaginationEntity pagination;

  const ClusterMediaPageEntity({required this.items, required this.pagination});
}
