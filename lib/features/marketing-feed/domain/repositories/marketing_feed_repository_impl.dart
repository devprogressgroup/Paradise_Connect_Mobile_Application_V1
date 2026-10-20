import 'package:dartz/dartz.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class MarketingFeedRepositoryImpl implements MarketingFeedRepository {
  final MarketingFeedRemoteDataSource remoteDataSource;

  MarketingFeedRepositoryImpl(this.remoteDataSource);

  Future<Either<String, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } catch (e) {
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, FeedPageEntity>> getFeedPosts({int page = 1, int perPage = 10}) =>
      _guard(() => remoteDataSource.getFeedPosts(page: page, perPage: perPage));

  @override
  Future<Either<String, FeedPostEntity>> getFeedPost(int postId) =>
      _guard(() => remoteDataSource.getFeedPost(postId));

  @override
  Future<Either<String, List<WallOfFameLevelEntity>>> getWallOfFame() =>
      _guard(() => remoteDataSource.getWallOfFame());

  @override
  Future<Either<String, PersonalFunnelEntity>> getPersonalFunnel() =>
      _guard(() => remoteDataSource.getPersonalFunnel());

  @override
  Future<Either<String, FeedPostEntity>> reactToPost(int postId, FeedReaction reaction) =>
      _guard(() => remoteDataSource.reactToPost(postId, reaction));

  @override
  Future<Either<String, FeedPostEntity>> votePoll(int postId, List<int> optionIndexes) =>
      _guard(() => remoteDataSource.votePoll(postId, optionIndexes));

  @override
  Future<Either<String, List<FeedCommentEntity>>> getComments(int postId) =>
      _guard(() => remoteDataSource.getComments(postId));

  @override
  Future<Either<String, List<FeedCommentEntity>>> addComment(int postId, String text, {int? parentId}) =>
      _guard(() => remoteDataSource.addComment(postId, text, parentId: parentId));

  @override
  Future<Either<String, List<FeedCommentEntity>>> toggleCommentLike(int postId, int commentId) =>
      _guard(() => remoteDataSource.toggleCommentLike(postId, commentId));

  @override
  Future<Either<String, FeedPostEntity>> shareMoment(ShareFeedMomentParams params) =>
      _guard(() => remoteDataSource.shareMoment(params));

  @override
  Future<Either<String, FeedPostEntity>> savePost(SaveFeedPostParams params) =>
      _guard(() => remoteDataSource.savePost(params));

  @override
  Future<Either<String, List<FeedPostEntity>>> getDrafts() =>
      _guard(() => remoteDataSource.getDrafts());

  @override
  Future<Either<String, FeedPostEntity>> publishNow(int postId) =>
      _guard(() => remoteDataSource.publishNow(postId));

  @override
  Future<Either<String, void>> deletePost(int postId) =>
      _guard(() => remoteDataSource.deletePost(postId));
}
