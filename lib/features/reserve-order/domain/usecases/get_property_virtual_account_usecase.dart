import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetPropertyVirtualAccountUseCase {
  final ReserveOrderRepository repository;

  GetPropertyVirtualAccountUseCase(this.repository);

  Future<Either<VirtualAccountFailure, PropertyVirtualAccountEntity>> call({
    required int townshipId,
    required int companyId,
    required int propertyId,
  }) async {
    return await repository.getPropertyVirtualAccount(
      townshipId: townshipId,
      companyId: companyId,
      propertyId: propertyId,
    );
  }
}
