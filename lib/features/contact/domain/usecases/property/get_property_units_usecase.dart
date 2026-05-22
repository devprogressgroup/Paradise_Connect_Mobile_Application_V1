import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/domain/entities/property/property_unit_entity.dart';
import '../../repositories/contact_repository.dart';

class GetPropertyUnitsUseCase {
  final ContactRepository repository;

  GetPropertyUnitsUseCase(this.repository);

  Future<Either<String, List<PropertyUnitCluster>>> call({required int townshipId}) async {
    return await repository.getPropertyUnits(townshipId: townshipId);
  }
}
