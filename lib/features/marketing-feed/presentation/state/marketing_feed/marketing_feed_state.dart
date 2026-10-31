import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';

enum MarketingFeedStatus { initial, loading, loadingMore, loaded, error }

class MarketingFeedState extends Equatable {
  final MarketingFeedStatus status;
  final List<FeedPostEntity> pinnedPosts;
  final List<FeedPostEntity> posts;
  final PersonalFunnelEntity? funnel;
  final List<WallOfFameLevelEntity> wallOfFame;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final String? errorMessage;

  const MarketingFeedState({
    this.status = MarketingFeedStatus.initial,
    this.pinnedPosts = const [],
    this.posts = const [],
    this.funnel,
    this.wallOfFame = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
    this.errorMessage,
  });

  MarketingFeedState copyWith({
    MarketingFeedStatus? status,
    List<FeedPostEntity>? pinnedPosts,
    List<FeedPostEntity>? posts,
    PersonalFunnelEntity? funnel,
    List<WallOfFameLevelEntity>? wallOfFame,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return MarketingFeedState(
      status: status ?? this.status,
      pinnedPosts: pinnedPosts ?? this.pinnedPosts,
      posts: posts ?? this.posts,
      funnel: funnel ?? this.funnel,
      wallOfFame: wallOfFame ?? this.wallOfFame,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pinnedPosts,
    posts,
    funnel,
    wallOfFame,
    currentPage,
    lastPage,
    hasMore,
    errorMessage,
  ];
}
