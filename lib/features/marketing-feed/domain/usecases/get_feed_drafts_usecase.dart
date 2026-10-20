import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetFeedDraftsUseCase {
  final MarketingFeedRepository repository;

  GetFeedDraftsUseCase(this.repository);

  Future<Either<String, List<FeedPostEntity>>> call() async {
    return await repository.getDrafts();
  }
}
