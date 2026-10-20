import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class ToggleFeedCommentLikeUseCase {
  final MarketingFeedRepository repository;

  ToggleFeedCommentLikeUseCase(this.repository);

  Future<Either<String, List<FeedCommentEntity>>> call(int postId, int commentId) async {
    return await repository.toggleCommentLike(postId, commentId);
  }
}
