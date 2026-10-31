import 'package:dartz/dartz.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Moderator: buat/edit post, poll, atau link.
class SaveFeedPostUseCase {
  final MarketingFeedRepository repository;

  SaveFeedPostUseCase(this.repository);

  Future<Either<MarketingFeedException, FeedPostEntity>> call(SaveFeedPostParams params) async {
    return await repository.savePost(params);
  }
}
