import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImageBytes(Uint8List bytes, {int maxSide = 0}) async {
  // Tanpa maxSide: perilaku lama (bytes apa adanya). Di mobile jalur yang dipakai memang
  // compressImageFile() — bytes mentah cuma muncul di web.
  if (maxSide <= 0) return bytes;

  try {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 85,
      minWidth: maxSide,
      minHeight: maxSide,
    );
    if (result.isNotEmpty) return Uint8List.fromList(result);
  } catch (_) {}

  return bytes;
}

Future<Uint8List> compressImageFile(String path) async {
  try {
    int quality = 80;
    Uint8List? result;
    do {
      result = await FlutterImageCompress.compressWithFile(
        path,
        quality: quality,
        minWidth: 1280,
        minHeight: 720,
      );
      if (result == null) break;
      quality -= 10;
    } while (result.lengthInBytes > 300 * 1024 && quality > 10);
    if (result != null) return result;
  } catch (_) {}
  return File(path).readAsBytes();
}
