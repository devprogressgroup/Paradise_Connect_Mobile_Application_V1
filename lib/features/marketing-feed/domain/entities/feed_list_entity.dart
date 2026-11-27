import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';

/// Badge satu baris dari backend: label yang ditampilkan dan tone warnanya (red | green | blue | orange | grey).
class FeedBadgeEntity {
  final String key;
  final String label;
  final String tone;

  const FeedBadgeEntity({required this.key, required this.label, required this.tone});
}

/// Satu baris di daftar Feeds: kiriman, atau kartu Wall of Fame. Tepat salah satu yang terisi.
class FeedListItem {
  final FeedPostEntity? post;
  final FameListCardEntity? fame;

  /// Badge dari backend. Null kalau respons tidak membawanya.
  final FeedBadgeEntity? badge;

  /// Tombol laporan dari backend, berurutan: dismiss | delete | takedown. Kosong = item tidak dilaporkan.
  final List<String> reportActions;

  const FeedListItem.post(
    FeedPostEntity this.post, {
    this.badge,
    this.reportActions = const [],
  }) : fame = null;
  const FeedListItem.fame(
    FameListCardEntity this.fame, {
    this.badge,
    this.reportActions = const [],
  }) : post = null;

  /// Item dengan laporan terbuka (ada tombol laporan dari backend).
  bool get isReported => reportActions.isNotEmpty;

  /// Kunci unik antara kiriman dan kartu fame (id keduanya bisa sama).
  String get key => post != null ? 'p${post!.id}' : 'f${fame!.id}';
}

/// Kartu Wall of Fame di daftar Feeds (hanya untuk user yang bisa mengelolanya).
class FameListCardEntity {
  final int id;
  final String kategori;
  final String program;
  final String? periode;
  final String? caption;
  final String status; // draft | scheduled | published
  final DateTime? publishAt;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final int? mediaId;
  final String? mediaType;
  final String? mediaUrl;
  final List<FameAdminWinnerEntity> winners;

  /// Pembuat kartu (dari API, default "Admin" di backend). Null kalau respons tidak membawanya.
  final FeedAuthorEntity? author;

  /// Jumlah laporan terbuka pada kartu (tab Dilaporkan).
  final int reportCount;

  /// True kalau saya sudah pernah melaporkan kartu ini.
  final bool myReport;

  /// Daftar laporan terbuka beserta pelapor (dipakai di detail kartu, untuk approver).
  final List<FeedReportNote> reports;

  const FameListCardEntity({
    this.reportCount = 0,
    this.myReport = false,
    this.reports = const [],
    required this.id,
    required this.kategori,
    required this.program,
    this.periode,
    this.caption,
    required this.status,
    this.publishAt,
    this.submittedAt,
    this.updatedAt,
    this.mediaId,
    this.mediaType,
    this.mediaUrl,
    this.winners = const [],
    this.author,
  });

  bool get isVideo => mediaType == 'video';
}

/// Satu halaman daftar Feeds gabungan.
class FeedListPageEntity {
  final List<FeedListItem> items;
  final int currentPage;
  final bool hasMore;

  const FeedListPageEntity({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });
}
