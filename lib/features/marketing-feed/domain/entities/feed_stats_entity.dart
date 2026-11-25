import 'package:equatable/equatable.dart';

/// Hitungan terbaru satu kiriman dari polling GET /api/marketing-feed/stats:
/// like, dislike, komentar, 2 komentar utama terbaru, dan hasil poll (kalau kiriman itu poll).
class FeedStatsEntity extends Equatable {
  final int id;
  final int likes;
  final int dislikes;
  final int comments;
  final List<FeedLatestCommentEntity> latestComments;
  final FeedPollStatsEntity? poll;

  const FeedStatsEntity({
    required this.id,
    required this.likes,
    required this.dislikes,
    required this.comments,
    this.latestComments = const [],
    this.poll,
  });

  @override
  List<Object?> get props => [
    id,
    likes,
    dislikes,
    comments,
    latestComments,
    poll,
  ];
}

/// Hasil poll terbaru: total pemilih, suara per opsi, dan pilihan user sendiri.
class FeedPollStatsEntity extends Equatable {
  final int totalVoters;
  final bool hasVoted;
  final List<int> myVotes;
  final List<FeedPollOptionStatsEntity> options;

  const FeedPollStatsEntity({
    required this.totalVoters,
    required this.hasVoted,
    this.myVotes = const [],
    this.options = const [],
  });

  @override
  List<Object?> get props => [totalVoters, hasVoted, myVotes, options];
}

/// Jumlah suara satu opsi poll (label tidak ikut, karena label tetap dari data poll).
class FeedPollOptionStatsEntity extends Equatable {
  final int index;
  final int votes;
  final int percent;

  const FeedPollOptionStatsEntity({
    required this.index,
    required this.votes,
    required this.percent,
  });

  @override
  List<Object?> get props => [index, votes, percent];
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
