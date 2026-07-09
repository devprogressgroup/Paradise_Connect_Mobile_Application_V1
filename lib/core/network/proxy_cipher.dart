import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class ProxyCipher {
  static const _keyStr = 'PdC0nn3ct2026Sec3tKey32BytesXz1!';
  static final _key = enc.Key.fromUtf8(_keyStr);

  static String encrypt(Map<String, dynamic> payload) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonEncode(payload), iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static dynamic decrypt(dynamic data) {
    if (data is! Map || !data.containsKey('e')) return data;
    try {
      final parts = (data['e'] as String).split(':');
      if (parts.length != 2) return data;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
      return jsonDecode(decrypted);
    } catch (_) {
      return data;
    }
  }

  static String encryptString(String plain) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String? decryptString(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
    } catch (_) {
      return null;
    }
  }
}
