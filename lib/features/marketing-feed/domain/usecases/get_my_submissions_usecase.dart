import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetMySubmissionsUseCase {
  final MarketingFeedRepository repository;

  GetMySubmissionsUseCase(this.repository);

  Future<Either<String, FeedPageEntity>> call({int page = 1, int perPage = 10}) async {
    return await repository.getMySubmissions(page: page, perPage: perPage);
  }
}
