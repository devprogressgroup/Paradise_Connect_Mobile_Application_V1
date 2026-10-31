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
      (data) => emit(state.copyWith(
        status: FeedCommentsStatus.loaded,
        comments: data.items,
        currentPage: data.currentPage,
        hasMore: data.hasMore,
      )),
    );
  }

  /// Halaman komentar utama berikutnya (infinite scroll).
  Future<void> loadMore() async {
    final postId = state.postId;
    if (postId == null || state.status != FeedCommentsStatus.loaded || !state.hasMore) return;
    emit(state.copyWith(status: FeedCommentsStatus.loadingMore));
    final result = await getFeedCommentsUseCase(postId, page: state.currentPage + 1);
    if (state.postId != postId) return;
    result.fold(
      (_) => emit(state.copyWith(status: FeedCommentsStatus.loaded)),
      (data) {
        // Komentar yang baru dikirim user sudah ditambahkan di akhir list — jangan dobel.
        final known = state.comments.map((c) => c.id).toSet();
        emit(state.copyWith(
          status: FeedCommentsStatus.loaded,
          comments: [...state.comments, ...data.items.where((c) => !known.contains(c.id))],
          currentPage: data.currentPage,
          hasMore: data.hasMore,
        ));
      },
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
      (newComment) {
        final current = state.comments;
        final List<FeedCommentEntity> updated;
        if (parentId == null) {
          updated = [...current, newComment];
        } else {
          updated = current.map((c) {
            if (c.id == parentId) {
              return c.copyWith(replies: [...c.replies, newComment]);
            }
            return c;
          }).toList();
        }
        emit(state.copyWith(isSending: false, comments: updated));
        return null;
      },
    );
  }

  /// Suka/batal suka — langsung tampil di UI, disinkronkan dengan hasil server atau dikembalikan kalau server gagal.
  /// Balikan: pesan error, atau null kalau sukses.
  Future<String?> toggleLike(int commentId) async {
    final postId = state.postId;
    if (postId == null) return null;
    final before = state.comments;

    bool wasLiked = false;
    for (final c in before) {
      if (c.id == commentId) {
        wasLiked = c.isLiked;
        break;
      }
      for (final r in c.replies) {
        if (r.id == commentId) {
          wasLiked = r.isLiked;
          break;
        }
      }
    }

    FeedCommentEntity flip(FeedCommentEntity c) => c.id == commentId
        ? c.copyWith(isLiked: !c.isLiked, likeCount: c.likeCount + (c.isLiked ? -1 : 1))
        : c.copyWith(replies: c.replies.map(flip).toList());
    emit(state.copyWith(comments: before.map(flip).toList()));

    final result = await toggleFeedCommentLikeUseCase(commentId, currentlyLiked: wasLiked);
    if (state.postId != postId) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(comments: before));
        return message;
      },
      (res) {
        FeedCommentEntity applyServer(FeedCommentEntity c) => c.id == commentId
            ? c.copyWith(isLiked: res.liked, likeCount: res.likeCount)
            : c.copyWith(replies: c.replies.map(applyServer).toList());
        emit(state.copyWith(comments: state.comments.map(applyServer).toList()));
        return null;
      },
    );
  }
}
