import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class AddFeedCommentUseCase {
  final MarketingFeedRepository repository;

  AddFeedCommentUseCase(this.repository);

  Future<Either<String, FeedCommentEntity>> call(int postId, String text, {int? parentId}) async {
    return await repository.addComment(postId, text, parentId: parentId);
  }
}
