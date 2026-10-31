import 'package:dartz/dartz.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';

abstract class MarketingFeedRepository {
  Future<Either<String, FeedPageEntity>> getFeedPosts({int page, int perPage});
  Future<Either<String, FeedPostEntity>> getFeedPost(int postId);
  Future<Either<String, List<WallOfFameLevelEntity>>> getWallOfFame();
  Future<Either<String, PersonalFunnelEntity>> getPersonalFunnel();
  Future<Either<String, PostReactionResult>> reactToPost(int postId, FeedReaction reaction);
  Future<Either<String, FeedPollEntity>> votePoll(int postId, List<int> optionIndexes);
  Future<Either<String, FeedCommentPageEntity>> getComments(int postId, {int page, int perPage});
  Future<Either<String, FeedCommentEntity>> addComment(int postId, String text, {int? parentId});
  Future<Either<String, CommentLikeResult>> toggleCommentLike(int commentId, {required bool currentlyLiked});
  Future<Either<MarketingFeedException, FeedPostEntity>> shareMoment(ShareFeedMomentParams params);
  Future<Either<String, FeedPageEntity>> getMySubmissions({int page, int perPage});

  // Moderator
  Future<Either<String, List<FeedPostEntity>>> getModeratorPosts();
  Future<Either<MarketingFeedException, FeedPostEntity>> savePost(SaveFeedPostParams params);
  Future<Either<String, void>> moderatorAction(int postId, String action);
}
