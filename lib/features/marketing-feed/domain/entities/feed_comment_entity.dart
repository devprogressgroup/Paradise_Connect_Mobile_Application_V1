import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';

/// Komentar di post Marketing Feed. Balasan cuma satu tingkat ([replies] milik komentar utama).
class FeedCommentEntity extends Equatable {
  final int id;
  final FeedAuthorEntity author;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final List<FeedCommentEntity> replies;

  const FeedCommentEntity({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  FeedCommentEntity copyWith({
    int? likeCount,
    bool? isLiked,
    List<FeedCommentEntity>? replies,
  }) {
    return FeedCommentEntity(
      id: id,
      author: author,
      text: text,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [id, author, text, createdAt, likeCount, isLiked, replies];
}
