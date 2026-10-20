import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

enum FeedCommentsStatus { initial, loading, loaded, error }

class FeedCommentsState extends Equatable {
  final FeedCommentsStatus status;
  final int? postId;
  final List<FeedCommentEntity> comments;
  final bool isSending;
  final String? errorMessage;

  const FeedCommentsState({
    this.status = FeedCommentsStatus.initial,
    this.postId,
    this.comments = const [],
    this.isSending = false,
    this.errorMessage,
  });

  int get totalCount => comments.fold(0, (n, c) => n + 1 + c.replies.length);

  FeedCommentsState copyWith({
    FeedCommentsStatus? status,
    List<FeedCommentEntity>? comments,
    bool? isSending,
    String? errorMessage,
  }) {
    return FeedCommentsState(
      status: status ?? this.status,
      postId: postId,
      comments: comments ?? this.comments,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, postId, comments, isSending, errorMessage];
}
