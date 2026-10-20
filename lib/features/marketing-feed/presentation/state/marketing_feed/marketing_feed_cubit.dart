import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_posts_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_personal_funnel_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_wall_of_fame_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/react_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/vote_feed_poll_usecase.dart';
import 'marketing_feed_state.dart';

/// State halaman Home (Marketing Feed): kartu Progress Kamu, Wall of Fame, dan aliran feed
/// (kiriman sendiri yang masih direview/ditolak di atas, lalu post yang sudah tayang).
class MarketingFeedCubit extends Cubit<MarketingFeedState> {
  final GetFeedPostsUseCase getFeedPostsUseCase;
  final GetFeedPostUseCase getFeedPostUseCase;
  final GetPersonalFunnelUseCase getPersonalFunnelUseCase;
  final GetWallOfFameUseCase getWallOfFameUseCase;
  final ReactFeedPostUseCase reactFeedPostUseCase;
  final VoteFeedPollUseCase voteFeedPollUseCase;

  MarketingFeedCubit({
    required this.getFeedPostsUseCase,
    required this.getFeedPostUseCase,
    required this.getPersonalFunnelUseCase,
    required this.getWallOfFameUseCase,
    required this.reactFeedPostUseCase,
    required this.voteFeedPollUseCase,
  }) : super(const MarketingFeedState());

  Future<void> fetch() async {
    emit(state.copyWith(status: MarketingFeedStatus.loading));

    final postsFuture = getFeedPostsUseCase(page: 1);
    final funnelFuture = getPersonalFunnelUseCase();
    final fameFuture = getWallOfFameUseCase();
    final posts = await postsFuture;
    final funnel = (await funnelFuture).fold((_) => state.funnel, (data) => data);
    final fame = (await fameFuture).fold((_) => state.wallOfFame, (data) => data);

    posts.fold(
      (message) => emit(state.copyWith(
        status: MarketingFeedStatus.error,
        funnel: funnel,
        wallOfFame: fame,
        errorMessage: message,
      )),
      (data) => emit(MarketingFeedState(
        status: MarketingFeedStatus.loaded,
        posts: data.items,
        funnel: funnel,
        wallOfFame: fame,
        currentPage: data.currentPage,
        lastPage: data.lastPage,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.status == MarketingFeedStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(status: MarketingFeedStatus.loadingMore));
    final result = await getFeedPostsUseCase(page: state.currentPage + 1);
    result.fold(
      (message) => emit(state.copyWith(status: MarketingFeedStatus.error, errorMessage: message)),
      (data) => emit(state.copyWith(
        status: MarketingFeedStatus.loaded,
        posts: [...state.posts, ...data.items],
        currentPage: data.currentPage,
        lastPage: data.lastPage,
      )),
    );
  }

  /// Ambil ulang satu post (mis. setelah sheet komentar ditutup) tanpa memuat ulang seluruh feed.
  Future<void> reloadPost(int postId) async {
    final result = await getFeedPostUseCase(postId);
    result.fold((_) {}, _replacePost);
  }

  /// Like/dislike — langsung tampil di UI (optimistic), dikembalikan kalau server gagal.
  /// Tap reaksi yang sama untuk membatalkan. Balikan: pesan error, atau null kalau sukses.
  Future<String?> react(int postId, FeedReaction tapped) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index < 0) return null;
    final before = state.posts[index];
    final next = before.myReaction == tapped ? FeedReaction.none : tapped;

    int count(int current, FeedReaction type) =>
        current - (before.myReaction == type ? 1 : 0) + (next == type ? 1 : 0);
    _replacePost(before.copyWith(
      myReaction: next,
      likeCount: count(before.likeCount, FeedReaction.like),
      dislikeCount: count(before.dislikeCount, FeedReaction.dislike),
    ));

    final result = await reactFeedPostUseCase(postId, next);
    return result.fold(
      (message) {
        _replacePost(before);
        return message;
      },
      (post) {
        _replacePost(post);
        return null;
      },
    );
  }

  /// Kirim jawaban poll. Balikan: pesan error, atau null kalau sukses.
  Future<String?> vote(int postId, List<int> optionIndexes) async {
    final result = await voteFeedPollUseCase(postId, optionIndexes);
    return result.fold((message) => message, (post) {
      _replacePost(post);
      return null;
    });
  }

  void _replacePost(FeedPostEntity post) {
    final index = state.posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final posts = [...state.posts]..[index] = post;
    emit(state.copyWith(posts: posts));
  }
}
