import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetFeedCommentsUseCase {
  final MarketingFeedRepository repository;

  GetFeedCommentsUseCase(this.repository);

  Future<Either<String, List<FeedCommentEntity>>> call(int postId) async {
    return await repository.getComments(postId);
  }
}
