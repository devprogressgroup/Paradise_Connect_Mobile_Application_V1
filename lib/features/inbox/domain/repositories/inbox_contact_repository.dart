import '../entities/inbox_contact_entity.dart';

abstract class InboxContactRepository {
  Future<(List<InboxContact> contacts, List<InboxContact> groups)> getContacts({String? search, int? cPage, int? gPage});
}