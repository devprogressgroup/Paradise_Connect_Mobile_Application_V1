import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Profil sales: punya sendiri (userId null) atau user lain (userId diisi), satu halaman per tab.
class GetMyProfileUseCase {
  final MarketingFeedRepository repository;

  GetMyProfileUseCase(this.repository);

  Future<Either<String, MyProfileEntity>> call({
    int? userId,
    String tab = 'semua',
    int page = 1,
    int perPage = 10,
  }) async {
    return await repository.getMyProfile(
      userId: userId,
      tab: tab,
      page: page,
      perPage: perPage,
    );
  }
}
