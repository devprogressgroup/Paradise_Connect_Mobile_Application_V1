import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_entity.dart';
import '../../entities/contact/create_contact_params.dart';
import '../../repositories/contact_repository.dart';

class CreateContactUseCase {
  final ContactRepository repository;

  CreateContactUseCase(this.repository);

  Future<Either<String, ContactEntity>> call(CreateContactParams params) async {
    return await repository.createContact(params);
  }
}
