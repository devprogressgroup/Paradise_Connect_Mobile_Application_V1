import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/home_ref_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';

enum MarketingFeedStatus { initial, loading, loadingMore, loaded, error }

class MarketingFeedState extends Equatable {
  final MarketingFeedStatus status;
  final List<FeedPostEntity> pinnedPosts;
  final List<FeedPostEntity> posts;
  /// Urutan Home dari server (kiriman + Wall of Fame), dipakai apa adanya.
  final List<HomeRefEntity> homeOrder;
  final PersonalFunnelEntity? funnel;
  final List<WallOfFameLevelEntity> wallOfFame;
  final List<FameProgramEntity> famePrograms;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final String? errorMessage;

  const MarketingFeedState({
    this.status = MarketingFeedStatus.initial,
    this.pinnedPosts = const [],
    this.posts = const [],
    this.homeOrder = const [],
    this.funnel,
    this.wallOfFame = const [],
    this.famePrograms = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
    this.errorMessage,
  });

  MarketingFeedState copyWith({
    MarketingFeedStatus? status,
    List<FeedPostEntity>? pinnedPosts,
    List<FeedPostEntity>? posts,
    List<HomeRefEntity>? homeOrder,
    PersonalFunnelEntity? funnel,
    List<WallOfFameLevelEntity>? wallOfFame,
    List<FameProgramEntity>? famePrograms,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return MarketingFeedState(
      status: status ?? this.status,
      pinnedPosts: pinnedPosts ?? this.pinnedPosts,
      posts: posts ?? this.posts,
      homeOrder: homeOrder ?? this.homeOrder,
      funnel: funnel ?? this.funnel,
      wallOfFame: wallOfFame ?? this.wallOfFame,
      famePrograms: famePrograms ?? this.famePrograms,
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
    homeOrder,
    funnel,
    wallOfFame,
    famePrograms,
    currentPage,
    lastPage,
    hasMore,
    errorMessage,
  ];
}
