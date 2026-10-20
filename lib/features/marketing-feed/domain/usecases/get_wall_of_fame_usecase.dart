import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetWallOfFameUseCase {
  final MarketingFeedRepository repository;

  GetWallOfFameUseCase(this.repository);

  Future<Either<String, List<WallOfFameLevelEntity>>> call() async {
    return await repository.getWallOfFame();
  }
}
