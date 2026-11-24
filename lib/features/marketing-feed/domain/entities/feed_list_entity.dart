import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Satu baris di daftar Feeds: kiriman, atau kartu Wall of Fame. Tepat salah satu yang terisi.
class FeedListItem {
  final FeedPostEntity? post;
  final FameListCardEntity? fame;

  const FeedListItem.post(FeedPostEntity this.post) : fame = null;
  const FeedListItem.fame(FameListCardEntity this.fame) : post = null;

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

  const FameListCardEntity({
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
