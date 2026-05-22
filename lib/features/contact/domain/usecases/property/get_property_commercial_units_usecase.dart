import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/property/property_unit_entity.dart';
import '../../repositories/contact_repository.dart';

class GetPropertyCommercialUnitsUseCase {
  final ContactRepository repository;

  GetPropertyCommercialUnitsUseCase(this.repository);

  Future<Either<String, List<PropertyUnitCluster>>> call({required int townshipId}) async {
    return await repository.getPropertyCommercialUnits(townshipId: townshipId);
  }
}
