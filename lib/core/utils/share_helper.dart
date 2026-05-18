import 'package:share_plus/share_plus.dart';
import '../../features/contact/domain/entities/contact/contact_entity.dart';

class ShareHelper {
  static void shareContact(ContactEntity contact) {
    final String text = "Name: ${contact.fullName}\nWhatsapp: https://wa.me/${contact.whatsappNumber ?? '-'}";
    
    Share.share(text);
  }
}
