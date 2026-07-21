import '../entities/cluster_media_entity.dart';
import '../repositories/saleskit_repository.dart';

class GetClusterMediaParams {
  final int clusterId;
  final MediaOwnerType ownerType;
  final int? mediaGroupId;
  final String? search;
  final String sortBy;
  final String sortDir;
  final int page;
  final int perPage;

  const GetClusterMediaParams({
    required this.clusterId,
    this.ownerType = MediaOwnerType.cluster,
    this.mediaGroupId,
    this.search,
    this.sortBy = 'name',
    this.sortDir = 'asc',
    this.page = 1,
    this.perPage = 10,
  });
}

class GetClusterMediaUseCase {
  final SalesKitRepository repository;
  GetClusterMediaUseCase(this.repository);

  Future<ClusterMediaPageEntity> call(GetClusterMediaParams params) => repository.getClusterMedia(
        clusterId: params.clusterId,
        ownerType: params.ownerType,
        mediaGroupId: params.mediaGroupId,
        search: params.search,
        sortBy: params.sortBy,
        sortDir: params.sortDir,
        page: params.page,
        perPage: params.perPage,
      );
}
