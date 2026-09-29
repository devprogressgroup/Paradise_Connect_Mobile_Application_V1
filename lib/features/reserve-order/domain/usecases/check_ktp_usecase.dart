import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class CheckKtpUseCase {
  final ReserveOrderRepository repository;

  CheckKtpUseCase(this.repository);

  Future<Either<String, Map<String, dynamic>>> call(
    String custKtp, {
    String? custName,
    int? contactId,
  }) async {
    return await repository.checkKtp(custKtp, custName: custName, contactId: contactId);
  }
}
