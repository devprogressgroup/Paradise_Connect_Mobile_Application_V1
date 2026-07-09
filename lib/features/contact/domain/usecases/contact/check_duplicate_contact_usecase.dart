import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_entity.dart';
import '../../repositories/contact_repository.dart';

class CheckDuplicateContactUseCase {
  final ContactRepository repository;

  CheckDuplicateContactUseCase(this.repository);

  Future<Either<String, ContactEntity?>> call({required int ownerId, required String phone}) async {
    return await repository.checkDuplicateContact(ownerId: ownerId, phone: phone);
  }
}
