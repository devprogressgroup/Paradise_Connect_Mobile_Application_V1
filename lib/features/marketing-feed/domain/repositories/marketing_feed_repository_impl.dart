import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_stats_entity.dart';
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
      if (e is MarketingFeedException) {
        return Left(e.message);
      }
      return Left(cleanErrorMessage(e));
    }
  }

  @override
  Future<Either<String, FeedPageEntity>> getFeedPosts({
    int page = 1,
    int perPage = 10,
  }) =>
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
  Future<Either<String, PostReactionResult>> reactToPost(
    int postId,
    FeedReaction reaction,
  ) => _guard(() => remoteDataSource.reactToPost(postId, reaction));

  @override
  Future<Either<String, FeedPollEntity>> votePoll(
    int postId,
    List<int> optionIndexes,
  ) => _guard(() => remoteDataSource.votePoll(postId, optionIndexes));

  @override
  Future<Either<String, FeedCommentPageEntity>> getComments(
    int postId, {
    int page = 1,
    int perPage = 10,
  }) => _guard(
    () => remoteDataSource.getComments(postId, page: page, perPage: perPage),
  );

  @override
  Future<Either<String, FeedCommentEntity>> addComment(
    int postId,
    String text, {
    int? parentId,
  }) => _guard(
    () => remoteDataSource.addComment(postId, text, parentId: parentId),
  );

  @override
  Future<Either<String, CommentLikeResult>> toggleCommentLike(
    int commentId, {
    required bool currentlyLiked,
  }) => _guard(
    () => remoteDataSource.toggleCommentLike(
      commentId,
      currentlyLiked: currentlyLiked,
    ),
  );

  @override
  Future<Either<MarketingFeedException, FeedPostEntity>> shareMoment(
    ShareFeedMomentParams params,
  ) async {
    try {
      return Right(await remoteDataSource.shareMoment(params));
    } catch (e) {
      return Left(parseMarketingFeedException(e, 'Gagal mengirim momen.'));
    }
  }

  @override
  @override
  Future<Either<String, List<FameProgramEntity>>> getFamePrograms() =>
      _guard(() => remoteDataSource.getFamePrograms());

  @override
  Future<Either<String, FameAccessEntity>> getFameAccess() =>
      _guard(() => remoteDataSource.getFameAccess());

  @override
  Future<Either<String, List<FameManageProgramEntity>>> getFameManage() =>
      _guard(() => remoteDataSource.getFameManage());

  @override
  Future<Either<String, List<FameCandidateEntity>>> getFameCandidates() =>
      _guard(() => remoteDataSource.getFameCandidates());

  @override
  Future<Either<String, PostReactionResult>> reactFameCard(
    int cardId,
    FeedReaction reaction,
  ) => _guard(() => remoteDataSource.reactFameCard(cardId, reaction));

  @override
  Future<Either<String, FeedCommentPageEntity>> getFameComments(
    int cardId, {
    int page = 1,
  }) => _guard(() => remoteDataSource.getFameComments(cardId, page: page));

  @override
  Future<Either<String, FeedCommentEntity>> addFameComment(
    int cardId,
    String text, {
    int? parentId,
  }) => _guard(
    () => remoteDataSource.addFameComment(cardId, text, parentId: parentId),
  );

  @override
  Future<Either<String, CommentLikeResult>> toggleFameCommentLike(
    int commentId, {
    required bool currentlyLiked,
  }) => _guard(
    () => remoteDataSource.toggleFameCommentLike(
      commentId,
      currentlyLiked: currentlyLiked,
    ),
  );

  @override
  Future<Either<String, FameAdminCardEntity>> saveFameCard(
    FameCardParams params, {
    int? cardId,
  }) => _guard(() => remoteDataSource.saveFameCard(params, cardId: cardId));

  @override
  Future<Either<String, FameAdminCardEntity>> setFameCardStatus(
    int cardId,
    String status,
    DateTime? publishAt,
  ) => _guard(
    () => remoteDataSource.setFameCardStatus(cardId, status, publishAt),
  );

  @override
  Future<Either<String, void>> uploadFameCardMedia(
    int cardId,
    FeedMediaEntity media,
  ) => _guard(() => remoteDataSource.uploadFameCardMedia(cardId, media));

  @override
  Future<Either<String, void>> deleteFameCardMedia(int cardId) =>
      _guard(() => remoteDataSource.deleteFameCardMedia(cardId));

  @override
  Future<Either<String, void>> deleteFameCard(int cardId) =>
      _guard(() => remoteDataSource.deleteFameCard(cardId));

  @override
  Future<Either<String, void>> setProfilePin(
    int postId, {
    required bool pinned,
  }) => _guard(() => remoteDataSource.setProfilePin(postId, pinned: pinned));

  @override
  Future<Either<String, FeedPageEntity>> getMySubmissions({
    int page = 1,
    int perPage = 10,
    String? status,
  }) => _guard(
    () => remoteDataSource.getMySubmissions(
      page: page,
      perPage: perPage,
      status: status,
    ),
  );
  @override
  Future<Either<String, FeedListPageEntity>> getFeedList({
    int page = 1,
    int perPage = 10,
    List<String> statuses = const [],
    List<String> kinds = const [],
    String q = '',
    String sort = 'latest',
    bool reported = false,
  }) => _guard(
    () => remoteDataSource.getFeedList(
      page: page,
      perPage: perPage,
      statuses: statuses,
      kinds: kinds,
      reported: reported,
      q: q,
      sort: sort,
    ),
  );

  @override
  Future<Either<String, Map<String, dynamic>>> getLinkMeta(String url) =>
      _guard(() => remoteDataSource.getLinkMeta(url));

  @override
  Future<Either<String, List<FeedPostEntity>>> getReviewQueue() =>
      _guard<List<FeedPostEntity>>(() async => remoteDataSource.getReviewQueue());

  @override
  Future<Either<String, void>> decideReview(int postId, String decision, {String? reason, String? publishAt}) =>
      _guard<void>(() => remoteDataSource.decideReview(postId, decision, reason: reason, publishAt: publishAt));

  @override
  Future<Either<String, List<FeedStatsEntity>>> getFeedStats(List<int> ids) =>
      _guard(() => remoteDataSource.getFeedStats(ids));

  @override
  Future<Either<String, MyProfileEntity>> getMyProfile({
    int? userId,
    String tab = 'semua',
    int page = 1,
    int perPage = 10,
  }) => _guard(
    () => remoteDataSource.getMyProfile(
      userId: userId,
      tab: tab,
      page: page,
      perPage: perPage,
    ),
  );

  @override
  Future<Either<String, FeedPageEntity>> searchFeedPosts({
    required String q,
    int page = 1,
    int perPage = 10,
  }) => _guard(
    () => remoteDataSource.searchFeedPosts(q: q, page: page, perPage: perPage),
  );

  @override
  Future<Either<String, List<FeedPostEntity>>> getModeratorPosts() =>
      _guard(() => remoteDataSource.getModeratorPosts());

  @override
  Future<Either<String, List<FeedPostEntity>>> getModeratorCalendar({
    required DateTime from,
    required DateTime to,
  }) => _guard(() => remoteDataSource.getModeratorCalendar(from: from, to: to));

  /// Sama dengan [shareMoment]: error dibiarkan utuh (kode STORAGE_ERROR, pesan Raptor) untuk dialog upload.
  @override
  Future<Either<MarketingFeedException, FeedPostEntity>> savePost(
    SaveFeedPostParams params,
  ) async {
    try {
      return Right(await remoteDataSource.savePost(params));
    } catch (e) {
      return Left(parseMarketingFeedException(e, 'Gagal menyimpan konten.'));
    }
  }

  @override
  Future<Either<String, void>> moderatorAction(int postId, String action) =>
      _guard(() => remoteDataSource.moderatorAction(postId, action));

  @override
  Future<Either<String, void>> reportPost(int postId, String reason, String? note) =>
      _guard(() => remoteDataSource.reportPost(postId, reason, note));

  @override
  Future<Either<String, List<FeedReportedPost>>> getReportedPosts() =>
      _guard<List<FeedReportedPost>>(() async => remoteDataSource.getReportedPosts());

  @override
  Future<Either<String, void>> decideReport(int postId, String action) =>
      _guard(() => remoteDataSource.decideReport(postId, action));

  @override
  Future<Either<String, List<FeedPostEntity>>> getPublishedPosts() =>
      _guard<List<FeedPostEntity>>(() async => remoteDataSource.getPublishedPosts());
}
