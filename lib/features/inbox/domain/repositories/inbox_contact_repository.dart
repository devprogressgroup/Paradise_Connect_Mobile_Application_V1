import '../entities/inbox_contact_entity.dart';
import '../entities/whatsapp_device_entity.dart';

abstract class InboxContactRepository {
  Future<(List<InboxContact> contacts, List<InboxContact> groups)> getContacts({String? search, int? cPage, int? gPage});
  Future<List<WhatsappDevice>> getWhatsappDevices();
  Future<void> getQrSession({required String session});
}