import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/add_feed_comment_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_comments_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/toggle_feed_comment_like_usecase.dart';
import 'feed_comments_state.dart';

/// State bottom sheet komentar satu target: kiriman biasa, atau kartu Wall of Fame ([FeedCommentsState.fameCard]).
class FeedCommentsCubit extends Cubit<FeedCommentsState> {
  final GetFeedCommentsUseCase getFeedCommentsUseCase;
  final AddFeedCommentUseCase addFeedCommentUseCase;
  final ToggleFeedCommentLikeUseCase toggleFeedCommentLikeUseCase;
  final MarketingFeedRepository repository;

  FeedCommentsCubit({
    required this.getFeedCommentsUseCase,
    required this.addFeedCommentUseCase,
    required this.toggleFeedCommentLikeUseCase,
    required this.repository,
  }) : super(const FeedCommentsState());

  // Satu titik cabang: kiriman biasa lewat usecase, kartu Wall of Fame lewat repository.
  Future<Either<String, FeedCommentPageEntity>> _page(int id, {int page = 1}) =>
      state.fameCard
      ? repository.getFameComments(id, page: page)
      : getFeedCommentsUseCase(id, page: page);

  Future<Either<String, FeedCommentEntity>> _add(
    int id,
    String text,
    int? parentId,
  ) => state.fameCard
      ? repository.addFameComment(id, text, parentId: parentId)
      : addFeedCommentUseCase(id, text, parentId: parentId);

  Future<Either<String, CommentLikeResult>> _like(
    int commentId,
    bool wasLiked,
  ) => state.fameCard
      ? repository.toggleFameCommentLike(commentId, currentlyLiked: wasLiked)
      : toggleFeedCommentLikeUseCase(commentId, currentlyLiked: wasLiked);

  Future<void> load(int postId, {bool fameCard = false}) async {
    emit(
      FeedCommentsState(
        status: FeedCommentsStatus.loading,
        postId: postId,
        fameCard: fameCard,
      ),
    );
    final result = await _page(postId);
    if (state.postId != postId) return;
    result.fold(
      (message) => emit(
        state.copyWith(status: FeedCommentsStatus.error, errorMessage: message),
      ),
      (data) => emit(
        state.copyWith(
          status: FeedCommentsStatus.loaded,
          comments: data.items,
          currentPage: data.currentPage,
          hasMore: data.hasMore,
        ),
      ),
    );
  }

  /// Halaman komentar utama berikutnya (infinite scroll).
  Future<void> loadMore() async {
    final postId = state.postId;
    if (postId == null ||
        state.status != FeedCommentsStatus.loaded ||
        !state.hasMore)
      return;
    emit(state.copyWith(status: FeedCommentsStatus.loadingMore));
    final result = await _page(postId, page: state.currentPage + 1);
    if (state.postId != postId) return;
    result.fold((_) => emit(state.copyWith(status: FeedCommentsStatus.loaded)), (
      data,
    ) {
      // Komentar yang baru dikirim user sudah ditambahkan di akhir list — jangan dobel.
      final known = state.comments.map((c) => c.id).toSet();
      emit(
        state.copyWith(
          status: FeedCommentsStatus.loaded,
          comments: [
            ...state.comments,
            ...data.items.where((c) => !known.contains(c.id)),
          ],
          currentPage: data.currentPage,
          hasMore: data.hasMore,
        ),
      );
    });
  }

  Timer? _live;

  /// Komentar baru saat sheet terbuka: dicek tiap 10 detik. Komentar baru ada di halaman terakhir
  /// (urut dari yang terlama), jadi yang dicek adalah halaman pertama (untuk total) dan halaman terakhir.
  void startLive() {
    _live?.cancel();
    _live = Timer.periodic(const Duration(seconds: 10), (_) => _refreshLive());
  }

  void stopLive() {
    _live?.cancel();
    _live = null;
  }

  @override
  Future<void> close() {
    stopLive();
    return super.close();
  }

  Future<void> _refreshLive() async {
    final postId = state.postId;
    if (postId == null ||
        state.status != FeedCommentsStatus.loaded ||
        state.isSending) {
      return;
    }
    final first = await _page(postId);
    if (state.postId != postId || isClosed) return;
    final head = first.fold((_) => null, (d) => d);
    if (head == null) return;

    var tail = head;
    final lastPage = head.total > 0 && head.perPage > 0
        ? (head.total / head.perPage).ceil()
        : 1;
    if (lastPage > 1) {
      final r = await _page(postId, page: lastPage);
      if (state.postId != postId || isClosed) return;
      final last = r.fold((_) => null, (d) => d);
      if (last == null) return;
      tail = last;
    }

    // Data terbaru untuk komentar yang sudah tampil; komentar yang belum dikenal ditambahkan di akhir.
    final fresh = <int, FeedCommentEntity>{
      for (final c in head.items) c.id: c,
      for (final c in tail.items) c.id: c,
    };
    final known = state.comments.map((c) => c.id).toSet();
    final merged = [
      for (final c in state.comments) fresh[c.id] ?? c,
      for (final c in tail.items)
        if (!known.contains(c.id)) c,
    ];
    if (listEquals(merged, state.comments)) return;
    emit(state.copyWith(comments: merged));
  }

  /// Balikan: pesan error, atau null kalau terkirim.
  Future<String?> send(String text, {int? parentId}) async {
    final postId = state.postId;
    if (postId == null || state.isSending) return null;
    emit(state.copyWith(isSending: true));
    final result = await _add(postId, text, parentId);
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
        ? c.copyWith(
            isLiked: !c.isLiked,
            likeCount: c.likeCount + (c.isLiked ? -1 : 1),
          )
        : c.copyWith(replies: c.replies.map(flip).toList());
    emit(state.copyWith(comments: before.map(flip).toList()));

    final result = await _like(commentId, wasLiked);
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
        emit(
          state.copyWith(comments: state.comments.map(applyServer).toList()),
        );
        return null;
      },
    );
  }
}
