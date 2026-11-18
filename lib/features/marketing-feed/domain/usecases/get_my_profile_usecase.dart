import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Profil sales: punya sendiri (userId null) atau user lain (userId diisi).
class GetMyProfileUseCase {
  final MarketingFeedRepository repository;

  GetMyProfileUseCase(this.repository);

  Future<Either<String, MyProfileEntity>> call({int? userId}) async {
    return await repository.getMyProfile(userId: userId);
  }
}
