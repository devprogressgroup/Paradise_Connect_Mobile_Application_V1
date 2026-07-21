import 'package:progress_group/features/saleskit/domain/entities/cluster_media_entity.dart';

class MediaCaptionModel extends MediaCaptionEntity {
  const MediaCaptionModel({
    required super.captionId,
    required super.name,
    required super.shareCount,
    required super.shareTotal,
    super.shareDatetime,
  });

  factory MediaCaptionModel.fromJson(Map<String, dynamic> json) {
    return MediaCaptionModel(
      captionId: json['caption_id'] ?? 0,
      name: json['name'] ?? '',
      shareCount: json['share_count'] ?? 0,
      shareTotal: json['share_total'] ?? 0,
      shareDatetime: json['share_datetime'],
    );
  }
}

class MediaItemModel extends MediaItemEntity {
  const MediaItemModel({
    required super.mediaId,
    required super.name,
    super.thumbnail,
    super.link,
    super.captions,
    required super.mediaGroupId,
    required super.groupName,
  });

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    final captionList = (json['caption'] as List<dynamic>? ?? [])
        .map((e) => MediaCaptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return MediaItemModel(
      mediaId: json['media_id'] ?? 0,
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'],
      link: json['link'],
      captions: captionList,
      mediaGroupId: json['media_group_id'] ?? 0,
      groupName: json['group_name'] ?? '',
    );
  }
}

class MediaPaginationModel extends MediaPaginationEntity {
  const MediaPaginationModel({
    required super.currentPage,
    required super.lastPage,
    required super.perPage,
    required super.total,
  });

  factory MediaPaginationModel.fromJson(Map<String, dynamic> json) {
    return MediaPaginationModel(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}

class ClusterMediaPageModel extends ClusterMediaPageEntity {
  const ClusterMediaPageModel({required super.items, required super.pagination});

  factory ClusterMediaPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => MediaItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] != null
        ? MediaPaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
        : const MediaPaginationModel(currentPage: 1, lastPage: 1, perPage: 10, total: 0);
    return ClusterMediaPageModel(items: items, pagination: pagination);
  }
}
