import '../entities/inbox_contact_entity.dart';
import '../entities/whatsapp_device_entity.dart';

abstract class InboxContactRepository {
  Future<(List<InboxContact> contacts, List<InboxContact> groups)> getContacts({
    String? search,
    int? cPage,
    int? gPage,
    List<int>? salesExecutiveIds,
    int? statusProspectId,
    String? startDate,
    String? endDate,
  });
  Future<List<WhatsappDevice>> getWhatsappDevices();
  Future<void> getQrSession({required String session});
  Future<void> requestPairCode({required String session});
}