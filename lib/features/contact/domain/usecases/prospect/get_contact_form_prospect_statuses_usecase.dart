import 'package:dartz/dartz.dart';
import '../../entities/prospect/prospect_status.dart';
import '../../repositories/contact_repository.dart';

class GetContactFormProspectStatusesUseCase {
  final ContactRepository repository;

  GetContactFormProspectStatusesUseCase(this.repository);

  Future<Either<String, List<ProspectStatusEntity>>> call({int? contactId}) async {
    return await repository.getContactFormProspectStatuses(contactId: contactId);
  }
}
