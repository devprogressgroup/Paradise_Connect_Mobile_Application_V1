import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_entity.dart';
import '../../entities/contact/create_contact_params.dart';
import '../../repositories/contact_repository.dart';

class UpdateContactUseCase {
  final ContactRepository repository;
  UpdateContactUseCase(this.repository);

  Future<Either<String, ContactEntity>> call(int id, CreateContactParams params) async {
    return await repository.updateContact(id, params);
  }
}
