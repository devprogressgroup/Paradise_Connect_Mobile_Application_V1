import 'package:share_plus/share_plus.dart';
import '../../features/contact/domain/entities/contact/contact_entity.dart';

class ShareHelper {
  static String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+62')) return '62${cleaned.substring(3)}';
    if (cleaned.startsWith('08')) return '628${cleaned.substring(2)}';
    return cleaned;
  }

  static void shareContact(ContactEntity contact) {
    final raw = contact.whatsappNumber ?? '';
    final phone = raw.isNotEmpty ? _normalizePhone(raw) : '-';
    final String text = "Name: ${contact.fullName}\nWhatsapp: https://wa.me/$phone";
    Share.share(text);
  }
}
