import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class DeleteFeedPostUseCase {
  final MarketingFeedRepository repository;

  DeleteFeedPostUseCase(this.repository);

  Future<Either<String, void>> call(int postId) async {
    return await repository.deletePost(postId);
  }
}
