import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

enum FeedCommentsStatus { initial, loading, loadingMore, loaded, error }

class FeedCommentsState extends Equatable {
  final FeedCommentsStatus status;
  final int? postId;
  final List<FeedCommentEntity> comments;
  final bool isSending;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const FeedCommentsState({
    this.status = FeedCommentsStatus.initial,
    this.postId,
    this.comments = const [],
    this.isSending = false,
    this.currentPage = 1,
    this.hasMore = false,
    this.errorMessage,
  });

  int get totalCount => comments.fold(0, (n, c) => n + 1 + c.replies.length);

  FeedCommentsState copyWith({
    FeedCommentsStatus? status,
    List<FeedCommentEntity>? comments,
    bool? isSending,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return FeedCommentsState(
      status: status ?? this.status,
      postId: postId,
      comments: comments ?? this.comments,
      isSending: isSending ?? this.isSending,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, postId, comments, isSending, currentPage, hasMore, errorMessage];
}
