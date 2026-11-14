import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Sematkan / lepas kiriman di profil sales sendiri (maks. 3, hanya kiriman tayang).
class SetProfilePinUseCase {
  final MarketingFeedRepository repository;

  SetProfilePinUseCase(this.repository);

  Future<Either<String, void>> call(int postId, {required bool pinned}) {
    return repository.setProfilePin(postId, pinned: pinned);
  }
}
