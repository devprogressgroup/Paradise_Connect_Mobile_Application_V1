import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class SaveFeedPostUseCase {
  final MarketingFeedRepository repository;

  SaveFeedPostUseCase(this.repository);

  Future<Either<String, FeedPostEntity>> call(SaveFeedPostParams params) async {
    return await repository.savePost(params);
  }
}
