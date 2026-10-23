import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

const _channel = MethodChannel('com.example.progress_group/contact_picker');

/// Kontak hasil picker: cuma nama & satu nomor telepon yang dipilih user.
class PickedContact {
  final String name;
  final String phone;

  const PickedContact({required this.name, required this.phone});
}

/// Buka picker kontak bawaan OS untuk memilih SATU kontak, tanpa izin baca seluruh buku kontak.
/// Android: picker nomor telepon (ACTION_PICK) lewat MainActivity — kebijakan Contacts Permission
/// Google Play melarang READ_CONTACTS untuk kebutuhan sesempit ini. iOS: CNContactPickerViewController
/// (lewat flutter_contacts) memang tidak butuh izin kontak.
class ContactPickerService {
  ContactPickerService._();

  /// Null kalau user membatalkan picker.
  static Future<PickedContact?> pickPhone() async {
    if (Platform.isAndroid) {
      final result = await _channel.invokeMapMethod<String, String?>('pickPhone');
      if (result == null) return null;
      return PickedContact(name: result['name'] ?? '', phone: result['phone'] ?? '');
    }
    final contact = await fc.FlutterContacts.native.showPicker(properties: {fc.ContactProperty.phone});
    if (contact == null) return null;
    return PickedContact(name: contact.displayName ?? '', phone: contact.phones.isNotEmpty ? contact.phones.first.number : '');
  }
}
