import 'package:equatable/equatable.dart';

/// Hitungan terbaru satu kiriman dari polling GET /api/marketing-feed/stats:
/// like, dislike, komentar, dan 2 komentar utama terbaru.
class FeedStatsEntity extends Equatable {
  final int id;
  final int likes;
  final int dislikes;
  final int comments;
  final List<FeedLatestCommentEntity> latestComments;

  const FeedStatsEntity({
    required this.id,
    required this.likes,
    required this.dislikes,
    required this.comments,
    this.latestComments = const [],
  });

  @override
  List<Object?> get props => [id, likes, dislikes, comments, latestComments];
}

/// Komentar utama terbaru dalam polling statistik.
class FeedLatestCommentEntity extends Equatable {
  final int id;
  final String authorName;
  final String body;
  final DateTime createdAt;

  const FeedLatestCommentEntity({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, authorName, body, createdAt];
}
