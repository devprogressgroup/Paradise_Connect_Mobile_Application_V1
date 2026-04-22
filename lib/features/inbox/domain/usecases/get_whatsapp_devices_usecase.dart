import '../entities/whatsapp_device_entity.dart';
import '../repositories/inbox_contact_repository.dart';

class GetWhatsappDevicesUsecase {
  final InboxContactRepository repository;

  GetWhatsappDevicesUsecase(this.repository);

  Future<List<WhatsappDevice>> call() {
    return repository.getWhatsappDevices();
  }
}
