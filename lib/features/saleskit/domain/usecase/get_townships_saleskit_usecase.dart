import '../entities/township_entity.dart';
import '../repositories/saleskit_repository.dart';

class GetTownshipsSalesKitUseCase {
  final SalesKitRepository repository;
  GetTownshipsSalesKitUseCase(this.repository);

  Future<List<TownshipEntity>> call() => repository.getTownshipsSalesKit();
}
