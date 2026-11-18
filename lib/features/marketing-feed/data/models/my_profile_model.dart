import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';

/// Parser respons GET /api/marketing-feed/me/profile (field data).
class MyProfileModel {
  static MyProfileEntity fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    final stats = Map<String, dynamic>.from(json['stats'] as Map);
    final posts = (json['posts'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (p) => MyProfilePostEntity(
            id: (p['id'] as num).toInt(),
            type: (p['type'] as String?) ?? 'post',
            text: p['text'] as String?,
            thumbUrl: p['thumb'] as String?,
            thumbKind: p['thumb_kind'] as String?,
            likes: (p['likes'] as num?)?.toInt() ?? 0,
            comments: (p['comments'] as num?)?.toInt() ?? 0,
            isProfilePinned: p['is_profile_pinned'] == true,
            publishedAt: DateTime.parse(p['published_at'] as String),
          ),
        )
        .toList();

    return MyProfileEntity(
      id: (user['id'] as num).toInt(),
      name: (user['name'] as String?) ?? '',
      initials: (user['initials'] as String?) ?? '',
      photoUrl: user['photo_url'] as String?,
      subtitle: (user['subtitle'] as String?) ?? 'Sales',
      postCount: (stats['posts'] as num?)?.toInt() ?? 0,
      likeCount: (stats['likes'] as num?)?.toInt() ?? 0,
      commentCount: (stats['comments'] as num?)?.toInt() ?? 0,
      posts: posts,
    );
  }
}
