import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

class GetPersonalFunnelUseCase {
  final MarketingFeedRepository repository;

  GetPersonalFunnelUseCase(this.repository);

  Future<Either<String, PersonalFunnelEntity>> call() async {
    return await repository.getPersonalFunnel();
  }
}
