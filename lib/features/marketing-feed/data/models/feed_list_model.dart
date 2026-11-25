import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';

/// Membaca respons GET /marketing-feed/list (data): items[] berisi kiriman (kind = post) atau kartu fame (kind = fame).
FeedListPageEntity parseFeedListPage(Map<String, dynamic> data) {
  final items = <FeedListItem>[];
  for (final raw in (data['items'] as List? ?? const [])) {
    final map = Map<String, dynamic>.from(raw as Map);
    items.add(
      map['kind'] == 'fame'
          ? FeedListItem.fame(_parseFameCard(map))
          : FeedListItem.post(FeedPostModel.fromJson(map)),
    );
  }
  return FeedListPageEntity(
    items: items,
    currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
    hasMore: data['has_more'] == true,
  );
}

FameListCardEntity _parseFameCard(Map<String, dynamic> raw) {
  final media = raw['media'] as Map?;
  return FameListCardEntity(
    id: (raw['id'] as num).toInt(),
    kategori: (raw['kategori'] ?? '') as String,
    program: (raw['program'] ?? '') as String,
    periode: raw['periode'] as String?,
    caption: raw['caption'] as String?,
    status: (raw['status'] ?? 'draft') as String,
    publishAt: _date(raw['publish_at']),
    submittedAt: _date(raw['submitted_at']),
    updatedAt: _date(raw['updated_at']),
    mediaId: (media?['id'] as num?)?.toInt(),
    mediaType: media?['type'] as String?,
    mediaUrl: media?['url'] as String?,
    author: raw['author'] is Map
        ? FeedAuthorModel.fromJson(
            Map<String, dynamic>.from(raw['author'] as Map),
          )
        : null,
    winners: [
      for (final w in (raw['winners'] as List? ?? const []))
        FameAdminWinnerEntity(
          userId: ((w as Map)['user_id'] as num).toInt(),
          name: (w['name'] ?? '') as String,
          ranking: (w['ranking'] as num).toInt(),
          peringkatLabel: w['peringkat_label'] as String?,
          posisiLabel: w['posisi_label'] as String?,
          timLabel: w['tim_label'] as String?,
        ),
    ],
  );
}

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
