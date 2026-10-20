import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/add_feed_comment_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_comments_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/toggle_feed_comment_like_usecase.dart';
import 'feed_comments_state.dart';

/// State bottom sheet komentar satu post.
class FeedCommentsCubit extends Cubit<FeedCommentsState> {
  final GetFeedCommentsUseCase getFeedCommentsUseCase;
  final AddFeedCommentUseCase addFeedCommentUseCase;
  final ToggleFeedCommentLikeUseCase toggleFeedCommentLikeUseCase;

  FeedCommentsCubit({
    required this.getFeedCommentsUseCase,
    required this.addFeedCommentUseCase,
    required this.toggleFeedCommentLikeUseCase,
  }) : super(const FeedCommentsState());

  Future<void> load(int postId) async {
    emit(FeedCommentsState(status: FeedCommentsStatus.loading, postId: postId));
    final result = await getFeedCommentsUseCase(postId);
    if (state.postId != postId) return;
    result.fold(
      (message) => emit(state.copyWith(status: FeedCommentsStatus.error, errorMessage: message)),
      (data) => emit(state.copyWith(status: FeedCommentsStatus.loaded, comments: data)),
    );
  }

  /// Balikan: pesan error, atau null kalau terkirim.
  Future<String?> send(String text, {int? parentId}) async {
    final postId = state.postId;
    if (postId == null || state.isSending) return null;
    emit(state.copyWith(isSending: true));
    final result = await addFeedCommentUseCase(postId, text, parentId: parentId);
    if (state.postId != postId) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(isSending: false));
        return message;
      },
      (data) {
        emit(state.copyWith(isSending: false, comments: data));
        return null;
      },
    );
  }

  /// Suka/batal suka — langsung tampil di UI, dikembalikan kalau server gagal.
  Future<void> toggleLike(int commentId) async {
    final postId = state.postId;
    if (postId == null) return;
    final before = state.comments;

    FeedCommentEntity flip(FeedCommentEntity c) => c.id == commentId
        ? c.copyWith(isLiked: !c.isLiked, likeCount: c.likeCount + (c.isLiked ? -1 : 1))
        : c.copyWith(replies: c.replies.map(flip).toList());
    emit(state.copyWith(comments: before.map(flip).toList()));

    final result = await toggleFeedCommentLikeUseCase(postId, commentId);
    if (state.postId != postId) return;
    result.fold(
      (_) => emit(state.copyWith(comments: before)),
      (data) => emit(state.copyWith(comments: data)),
    );
  }
}
