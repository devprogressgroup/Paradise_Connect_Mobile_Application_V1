import '../entities/cluster_entity.dart';
import '../repositories/saleskit_repository.dart';

class GetClustersUseCase {
  final SalesKitRepository repository;
  GetClustersUseCase(this.repository);

  Future<List<ClusterEntity>> call(int townshipId) => repository.getClusters(townshipId);
}
