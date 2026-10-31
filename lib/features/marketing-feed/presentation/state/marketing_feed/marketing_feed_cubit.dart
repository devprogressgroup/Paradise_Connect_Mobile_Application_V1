import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_posts_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_my_submissions_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_personal_funnel_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_wall_of_fame_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/react_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/vote_feed_poll_usecase.dart';
import 'marketing_feed_state.dart';

/// State halaman Home (Marketing Feed): kartu Progress Kamu, Wall of Fame, konten disematkan,
/// dan aliran feed terbaru.
class MarketingFeedCubit extends Cubit<MarketingFeedState> {
  final GetFeedPostsUseCase getFeedPostsUseCase;
  final GetFeedPostUseCase getFeedPostUseCase;
  final GetPersonalFunnelUseCase getPersonalFunnelUseCase;
  final GetWallOfFameUseCase getWallOfFameUseCase;
  final ReactFeedPostUseCase reactFeedPostUseCase;
  final VoteFeedPollUseCase voteFeedPollUseCase;
  final GetMySubmissionsUseCase getMySubmissionsUseCase;

  MarketingFeedCubit({
    required this.getFeedPostsUseCase,
    required this.getFeedPostUseCase,
    required this.getPersonalFunnelUseCase,
    required this.getWallOfFameUseCase,
    required this.reactFeedPostUseCase,
    required this.voteFeedPollUseCase,
    required this.getMySubmissionsUseCase,
  }) : super(const MarketingFeedState());

  Future<void> fetch() async {
    emit(state.copyWith(status: MarketingFeedStatus.loading));

    final postsFuture = getFeedPostsUseCase(page: 1);
    final funnelFuture = getPersonalFunnelUseCase();
    final fameFuture = getWallOfFameUseCase();

    final postsResult = await postsFuture;
    final funnel = (await funnelFuture).fold((_) => state.funnel, (data) => data);
    final fame = (await fameFuture).fold((_) => state.wallOfFame, (data) => data);

    postsResult.fold(
      (message) => emit(state.copyWith(
        status: MarketingFeedStatus.error,
        funnel: funnel,
        wallOfFame: fame,
        errorMessage: message,
      )),
      (data) => emit(MarketingFeedState(
        status: MarketingFeedStatus.loaded,
        pinnedPosts: data.pinned,
        posts: data.items,
        funnel: funnel,
        wallOfFame: fame,
        currentPage: data.currentPage,
        lastPage: data.lastPage,
        hasMore: data.hasMore,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.status == MarketingFeedStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(status: MarketingFeedStatus.loadingMore));
    final result = await getFeedPostsUseCase(page: state.currentPage + 1);
    result.fold(
      // Tetap `loaded` supaya scroll berikutnya mencoba lagi; daftar yang sudah ada tidak hilang.
      (message) => emit(state.copyWith(status: MarketingFeedStatus.loaded, errorMessage: message)),
      (data) => emit(state.copyWith(
        status: MarketingFeedStatus.loaded,
        posts: [...state.posts, ...data.items],
        currentPage: data.currentPage,
        lastPage: data.lastPage,
        hasMore: data.hasMore,
      )),
    );
  }

  /// Ambil ulang satu post (mis. setelah sheet komentar ditutup atau notif dibuka)
  /// tanpa memuat ulang seluruh feed.
  Future<void> reloadPost(int postId) async {
    await getPost(postId);
  }

  /// Detail satu post (halaman detail / notifikasi). Salinan di feed ikut diperbarui.
  Future<Either<String, FeedPostEntity>> getPost(int postId) async {
    final result = await getFeedPostUseCase(postId);
    result.fold((_) {}, _replacePost);
    return result;
  }

  /// Kiriman "Bagikan Momen" milik user (semua status review).
  Future<Either<String, FeedPageEntity>> getMySubmissions({int page = 1}) =>
      getMySubmissionsUseCase(page: page);

  /// Kirim reaksi untuk post yang dipegang halaman lain (detail) — optimistic update & rollback
  /// diurus pemanggil; salinan di feed disamakan dengan angka server.
  Future<Either<String, PostReactionResult>> sendReaction(int postId, FeedReaction next) async {
    final result = await reactFeedPostUseCase(postId, next);
    result.fold((_) {}, (res) {
      final current = _findPost(postId);
      if (current != null) {
        _replacePost(current.copyWith(myReaction: res.myReaction, likeCount: res.likes, dislikeCount: res.dislikes));
      }
    });
    return result;
  }

  /// Like/dislike — langsung tampil di UI (optimistic), disinkronkan dengan angka server
  /// atau di-rollback kalau gagal.
  Future<String?> react(int postId, FeedReaction tapped) async {
    final before = _findPost(postId);
    if (before == null) return null;

    final next = before.myReaction == tapped ? FeedReaction.none : tapped;

    int count(int current, FeedReaction type) =>
        current - (before.myReaction == type ? 1 : 0) + (next == type ? 1 : 0);

    final optimistic = before.copyWith(
      myReaction: next,
      likeCount: count(before.likeCount, FeedReaction.like),
      dislikeCount: count(before.dislikeCount, FeedReaction.dislike),
    );
    _replacePost(optimistic);

    final result = await reactFeedPostUseCase(postId, next);
    return result.fold(
      (message) {
        _replacePost(before);
        return message;
      },
      (res) {
        final synced = before.copyWith(
          myReaction: res.myReaction,
          likeCount: res.likes,
          dislikeCount: res.dislikes,
        );
        _replacePost(synced);
        return null;
      },
    );
  }

  /// Kirim jawaban poll. Balikan: pesan error, atau null kalau sukses.
  Future<String?> vote(int postId, List<int> optionIndexes) async {
    final result = await submitVote(postId, optionIndexes);
    return result.fold((message) => message, (_) => null);
  }

  /// Kirim jawaban poll dan kembalikan poll terbaru dari server; salinan di feed ikut diperbarui.
  Future<Either<String, FeedPollEntity>> submitVote(int postId, List<int> optionIndexes) async {
    final result = await voteFeedPollUseCase(postId, optionIndexes);
    result.fold((_) {}, (newPoll) {
      final target = _findPost(postId);
      if (target != null) _replacePost(target.copyWith(poll: newPoll));
    });
    return result;
  }

  FeedPostEntity? _findPost(int postId) {
    for (final p in [...state.pinnedPosts, ...state.posts]) {
      if (p.id == postId) return p;
    }
    return null;
  }

  void _replacePost(FeedPostEntity post) {
    var changed = false;
    List<FeedPostEntity> pinned = state.pinnedPosts;
    List<FeedPostEntity> regular = state.posts;

    final pIndex = pinned.indexWhere((p) => p.id == post.id);
    if (pIndex >= 0) {
      pinned = [...pinned]..[pIndex] = post;
      changed = true;
    }

    final rIndex = regular.indexWhere((p) => p.id == post.id);
    if (rIndex >= 0) {
      regular = [...regular]..[rIndex] = post;
      changed = true;
    }

    if (changed) {
      emit(state.copyWith(pinnedPosts: pinned, posts: regular));
    }
  }
}
