import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';

/// Membaca respons GET /marketing-feed/list (data): items[] berisi kiriman (kind = post) atau kartu fame (kind = fame).
FeedListPageEntity parseFeedListPage(Map<String, dynamic> data) {
  final items = <FeedListItem>[];
  for (final raw in (data['items'] as List? ?? const [])) {
    final map = Map<String, dynamic>.from(raw as Map);
    final badge = _parseBadge(map['badge']);
    final actions = _parseReportActions(map['report_actions']);
    items.add(
      map['kind'] == 'fame'
          ? FeedListItem.fame(
              _parseFameCard(map),
              badge: badge,
              reportActions: actions,
            )
          : FeedListItem.post(
              FeedPostModel.fromJson(map),
              badge: badge,
              reportActions: actions,
            ),
    );
  }
  return FeedListPageEntity(
    items: items,
    currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
    hasMore: data['has_more'] == true,
  );
}

/// Kartu fame dari respons apa pun yang memakai bentuk yang sama (mis. laporan moderator).
FameListCardEntity parseFameListCard(Map<String, dynamic> raw) => _parseFameCard(raw);

FameListCardEntity _parseFameCard(Map<String, dynamic> raw) {
  final media = raw['media'] as Map?;
  return FameListCardEntity(
    id: (raw['id'] as num).toInt(),
    kategori: (raw['kategori'] ?? '') as String,
    program: (raw['program'] ?? '') as String,
    periode: raw['periode'] as String?,
    caption: raw['caption'] as String?,
    reportCount: (raw['report_count'] as num?)?.toInt() ?? 0,
    myReport: raw['my_report'] == true,
    reports: [
      for (final r in (raw['reports'] as List? ?? const []))
        _parseReportNote(Map<String, dynamic>.from(r as Map)),
    ],
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

/// Satu laporan kartu fame: bentuk sama dengan laporan di detail kiriman.
FeedReportNote _parseReportNote(Map<String, dynamic> m) => FeedReportNote(
  reason: (m['reason'] ?? 'lainnya') as String,
  note: m['note'] as String?,
  createdAt: _date(m['created_at']) ?? DateTime.now(),
  reporterName: (m['reporter_name'] ?? 'User') as String,
);

FeedBadgeEntity? _parseBadge(Object? raw) {
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  return FeedBadgeEntity(
    key: (m['key'] ?? '') as String,
    label: (m['label'] ?? '') as String,
    tone: (m['tone'] ?? 'grey') as String,
  );
}

List<String> _parseReportActions(Object? raw) =>
    raw is List ? raw.whereType<String>().toList() : const [];

// Waktu server dipetakan ke jam dinding WIB (sama seperti FeedPostModel), supaya "Dibuat … lalu" tidak bergeser 7 jam.
DateTime? _date(Object? raw) => raw is String ? DateHelper.parseServerTime(raw) : null;
