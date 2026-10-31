import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class VoteFeedPollUseCase {
  final MarketingFeedRepository repository;

  VoteFeedPollUseCase(this.repository);

  Future<Either<String, FeedPollEntity>> call(int postId, List<int> optionIndexes) async {
    return await repository.votePoll(postId, optionIndexes);
  }
}
