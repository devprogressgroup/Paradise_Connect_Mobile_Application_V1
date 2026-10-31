import 'package:dartz/dartz.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class ShareFeedMomentUseCase {
  final MarketingFeedRepository repository;

  ShareFeedMomentUseCase(this.repository);

  Future<Either<MarketingFeedException, FeedPostEntity>> call(ShareFeedMomentParams params) async {
    return await repository.shareMoment(params);
  }
}
