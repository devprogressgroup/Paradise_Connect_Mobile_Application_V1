import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class ToggleFeedCommentLikeUseCase {
  final MarketingFeedRepository repository;

  ToggleFeedCommentLikeUseCase(this.repository);

  Future<Either<String, CommentLikeResult>> call(int commentId, {required bool currentlyLiked}) async {
    return await repository.toggleCommentLike(commentId, currentlyLiked: currentlyLiked);
  }
}
