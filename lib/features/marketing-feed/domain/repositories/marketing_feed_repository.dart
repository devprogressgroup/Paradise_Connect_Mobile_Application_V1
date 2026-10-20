import 'package:dartz/dartz.dart';
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
  Future<Either<String, FeedPostEntity>> reactToPost(int postId, FeedReaction reaction);
  Future<Either<String, FeedPostEntity>> votePoll(int postId, List<int> optionIndexes);
  Future<Either<String, List<FeedCommentEntity>>> getComments(int postId);
  Future<Either<String, List<FeedCommentEntity>>> addComment(int postId, String text, {int? parentId});
  Future<Either<String, List<FeedCommentEntity>>> toggleCommentLike(int postId, int commentId);
  Future<Either<String, FeedPostEntity>> shareMoment(ShareFeedMomentParams params);
  Future<Either<String, FeedPostEntity>> savePost(SaveFeedPostParams params);
  Future<Either<String, List<FeedPostEntity>>> getDrafts();
  Future<Either<String, FeedPostEntity>> publishNow(int postId);
  Future<Either<String, void>> deletePost(int postId);
}
