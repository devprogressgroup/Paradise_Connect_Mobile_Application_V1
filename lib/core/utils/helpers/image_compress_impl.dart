import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImageBytes(Uint8List bytes) async => bytes;

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
