import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';

class FeedAuthorModel extends FeedAuthorEntity {
  const FeedAuthorModel({
    super.id,
    required super.name,
    super.initials,
    super.badge,
    super.subtitle,
    super.photoUrl,
    super.isOfficial,
  });

  factory FeedAuthorModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '-';
    final initials = json['initials'] as String? ?? '';
    final badge = json['badge'] as String? ?? json['subtitle'] as String?;
    return FeedAuthorModel(
      id: json['id'] as int? ?? 0,
      name: name,
      initials: initials,
      badge: badge,
      subtitle: badge,
      photoUrl: json['photo_url'] as String?,
      isOfficial: json['is_official'] == true || json['is_moderator'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initials': initials,
    'badge': badge,
    'photo_url': photoUrl,
    'is_official': isOfficial,
  };
}
