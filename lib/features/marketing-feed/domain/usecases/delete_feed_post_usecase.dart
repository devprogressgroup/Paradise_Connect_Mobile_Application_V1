import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Moderator: hapus draft / konten terjadwal (soft delete).
class DeleteFeedPostUseCase {
  final MarketingFeedRepository repository;

  DeleteFeedPostUseCase(this.repository);

  Future<Either<String, void>> call(int postId) async {
    return await repository.moderatorAction(postId, 'del');
  }
}
