import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetFeedPostsUseCase {
  final MarketingFeedRepository repository;

  GetFeedPostsUseCase(this.repository);

  Future<Either<String, FeedPageEntity>> call({int page = 1, int perPage = 10}) async {
    return await repository.getFeedPosts(page: page, perPage: perPage);
  }
}
