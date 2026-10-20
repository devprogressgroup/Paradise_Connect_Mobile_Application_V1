import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class ReactFeedPostUseCase {
  final MarketingFeedRepository repository;

  ReactFeedPostUseCase(this.repository);

  Future<Either<String, FeedPostEntity>> call(int postId, FeedReaction reaction) async {
    return await repository.reactToPost(postId, reaction);
  }
}
