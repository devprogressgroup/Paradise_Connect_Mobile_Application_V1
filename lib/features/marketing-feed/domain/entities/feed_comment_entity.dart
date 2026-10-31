import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';

/// Komentar di post Marketing Feed. Balasan cuma satu tingkat ([replies] milik komentar utama).
class FeedCommentEntity extends Equatable {
  final int id;
  final int? parentId;
  final FeedAuthorEntity author;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final bool isMine;
  final List<FeedCommentEntity> replies;

  const FeedCommentEntity({
    required this.id,
    this.parentId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.isMine = false,
    this.replies = const [],
  });

  FeedCommentEntity copyWith({
    int? likeCount,
    bool? isLiked,
    bool? isMine,
    List<FeedCommentEntity>? replies,
  }) {
    return FeedCommentEntity(
      id: id,
      parentId: parentId,
      author: author,
      text: text,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isMine: isMine ?? this.isMine,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [id, parentId, author, text, createdAt, likeCount, isLiked, isMine, replies];
}

/// Satu halaman komentar utama (tiap komentar sudah membawa semua balasannya).
class FeedCommentPageEntity extends Equatable {
  final List<FeedCommentEntity> items;
  final int currentPage;
  final bool hasMore;

  const FeedCommentPageEntity({
    required this.items,
    this.currentPage = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [items, currentPage, hasMore];
}
