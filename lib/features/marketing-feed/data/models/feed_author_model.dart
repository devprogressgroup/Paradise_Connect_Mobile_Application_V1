import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';

class FeedAuthorModel extends FeedAuthorEntity {
  const FeedAuthorModel({
    required super.id,
    required super.name,
    super.subtitle,
    super.photoUrl,
    super.isModerator,
  });

  factory FeedAuthorModel.fromJson(Map<String, dynamic> json) {
    return FeedAuthorModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '-',
      subtitle: json['subtitle'] as String?,
      photoUrl: json['photo_url'] as String?,
      isModerator: json['is_moderator'] == true,
    );
  }
}
