import '../entities/inbox_contact_entity.dart';
import '../repositories/inbox_contact_repository.dart';

class GetInboxContactsUsecase {
  final InboxContactRepository repository;

  GetInboxContactsUsecase(this.repository);

  Future<(List<InboxContact>, List<InboxContact>)> call({String? search, int? cPage, int? gPage}) {
    return repository.getContacts(search: search, cPage: cPage, gPage: gPage);
  }
}