import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Moderator: tayangkan draft / konten terjadwal sekarang juga.
class PublishFeedPostNowUseCase {
  final MarketingFeedRepository repository;

  PublishFeedPostNowUseCase(this.repository);

  Future<Either<String, void>> call(int postId) async {
    return await repository.moderatorAction(postId, 'now');
  }
}
