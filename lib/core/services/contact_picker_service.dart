import 'package:flutter/services.dart';

const _channel = MethodChannel('com.example.progress_group/contact_picker');

typedef PickedContact = ({String name, String phone});

/// Android-only. Picker nomor telepon sistem (lihat pickPhoneLauncher di MainActivity) —
/// app cuma dapat akses ke kontak yang dipilih user, tanpa izin READ_CONTACTS yang dibatasi
/// kebijakan Izin Kontak Google Play.
class ContactPickerService {
  /// Return null kalau user batal memilih.
  static Future<PickedContact?> pickPhone() async {
    final result = await _channel.invokeMapMethod<String, String?>('pickPhone');
    if (result == null) return null;
    return (name: result['name'] ?? '', phone: result['phone'] ?? '');
  }
}
