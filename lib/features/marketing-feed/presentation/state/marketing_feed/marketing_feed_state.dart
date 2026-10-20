import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';

enum MarketingFeedStatus { initial, loading, loadingMore, loaded, error }

class MarketingFeedState extends Equatable {
  final MarketingFeedStatus status;
  final List<FeedPostEntity> posts;
  final PersonalFunnelEntity? funnel;
  final List<WallOfFameLevelEntity> wallOfFame;
  final int currentPage;
  final int lastPage;
  final String? errorMessage;

  const MarketingFeedState({
    this.status = MarketingFeedStatus.initial,
    this.posts = const [],
    this.funnel,
    this.wallOfFame = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.errorMessage,
  });

  bool get hasMore => currentPage < lastPage;

  MarketingFeedState copyWith({
    MarketingFeedStatus? status,
    List<FeedPostEntity>? posts,
    PersonalFunnelEntity? funnel,
    List<WallOfFameLevelEntity>? wallOfFame,
    int? currentPage,
    int? lastPage,
    String? errorMessage,
  }) {
    return MarketingFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      funnel: funnel ?? this.funnel,
      wallOfFame: wallOfFame ?? this.wallOfFame,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, posts, funnel, wallOfFame, currentPage, lastPage, errorMessage];
}
