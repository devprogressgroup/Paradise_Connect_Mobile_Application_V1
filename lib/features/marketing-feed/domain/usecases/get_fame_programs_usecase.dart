import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Wall of Fame baru: program > kategori > peringkat (semua peringkat, satu kartu per orang).
class GetFameProgramsUseCase {
  final MarketingFeedRepository repository;

  GetFameProgramsUseCase(this.repository);

  Future<Either<String, List<FameProgramEntity>>> call() {
    return repository.getFamePrograms();
  }
}
