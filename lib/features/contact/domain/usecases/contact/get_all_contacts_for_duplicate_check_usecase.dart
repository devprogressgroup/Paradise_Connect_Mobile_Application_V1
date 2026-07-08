import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_entity.dart';
import '../../repositories/contact_repository.dart';

class GetAllContactsForDuplicateCheckUseCase {
  final ContactRepository repository;

  GetAllContactsForDuplicateCheckUseCase(this.repository);

  Future<Either<String, List<ContactEntity>>> call() {
    return repository.getAllContactsForDuplicateCheck();
  }
}
