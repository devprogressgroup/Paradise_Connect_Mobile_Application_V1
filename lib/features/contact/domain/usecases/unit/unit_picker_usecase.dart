import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import '../../repositories/contact_repository.dart';

class GetUnitHierarchyUseCase {
  final ContactRepository repository;
  GetUnitHierarchyUseCase(this.repository);

  Future<Either<String, List<UnitCluster>>> call({required int townshipId, String? search}) =>
      repository.getUnitHierarchy(townshipId: townshipId, search: search);
}

class GetUnitLotsUseCase {
  final ContactRepository repository;
  GetUnitLotsUseCase(this.repository);

  Future<Either<String, List<UnitLot>>> call({required int productId, String? search}) =>
      repository.getUnitLots(productId: productId, search: search);
}
