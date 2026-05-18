import 'package:dartz/dartz.dart';
import '../../entities/contact/contact_entity.dart';
import '../../repositories/contact_repository.dart';

class GetContactDetailUseCase {
  final ContactRepository repository;

  GetContactDetailUseCase(this.repository);

  Future<Either<String, ContactEntity>> call(int id) async {
    return await repository.getContactDetail(id);
  }
}
