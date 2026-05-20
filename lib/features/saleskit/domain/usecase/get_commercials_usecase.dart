import '../entities/commercial_entity.dart';
import '../repositories/saleskit_repository.dart';

class GetCommercialsUseCase {
  final SalesKitRepository repository;
  GetCommercialsUseCase(this.repository);

  Future<List<CommercialEntity>> call(int townshipId) => repository.getCommercials(townshipId);
}
