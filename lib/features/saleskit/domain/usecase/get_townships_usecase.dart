import '../entities/township_entity.dart';
import '../repositories/saleskit_repository.dart';

class GetTownshipsUseCase {
  final SalesKitRepository repository;
  GetTownshipsUseCase(this.repository);

  Future<List<TownshipEntity>> call() => repository.getTownships();
}
