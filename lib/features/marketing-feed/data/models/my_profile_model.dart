import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';

/// Parser respons GET /api/marketing-feed/me/profile dan users/{id}/profile (field data).
/// `items`, `current_page`, `per_page`, `total`, `has_more` memakai format halaman feed yang sama.
class MyProfileModel {
  static MyProfileEntity fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    final stats = Map<String, dynamic>.from(json['stats'] as Map);
    final page = FeedPageModel.fromJson(json);
    final rawCounts = Map<String, dynamic>.from(
      json['counts'] as Map? ?? const {},
    );

    return MyProfileEntity(
      id: (user['id'] as num).toInt(),
      name: (user['name'] as String?) ?? '',
      initials: (user['initials'] as String?) ?? '',
      photoUrl: user['photo_url'] as String?,
      subtitle: (user['subtitle'] as String?) ?? 'Sales',
      postCount: (stats['posts'] as num?)?.toInt() ?? 0,
      likeCount: (stats['likes'] as num?)?.toInt() ?? 0,
      commentCount: (stats['comments'] as num?)?.toInt() ?? 0,
      tab: (json['tab'] as String?) ?? 'semua',
      counts: rawCounts.map((k, v) => MapEntry(k, (v as num).toInt())),
      items: page.items,
      currentPage: page.currentPage,
      total: page.total,
      hasMore: page.hasMore,
    );
  }
}
