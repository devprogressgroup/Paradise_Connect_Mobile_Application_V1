import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class PublishFeedPostNowUseCase {
  final MarketingFeedRepository repository;

  PublishFeedPostNowUseCase(this.repository);

  Future<Either<String, FeedPostEntity>> call(int postId) async {
    return await repository.publishNow(postId);
  }
}
