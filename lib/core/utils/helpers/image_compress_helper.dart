import 'dart:typed_data';

import 'image_compress_impl.dart'
    if (dart.library.html) 'image_compress_web.dart' as _impl;

/// [maxSide] = batas sisi terpanjang gambar (px). 0 = tanpa batas (perilaku lama, dipakai
/// pemanggil yang sudah ada). Dipakai KTP OCR: request mobile masuk lewat gateway `/px` yang
/// membungkus file jadi base64 di dalam body JSON, jadi ukuran file berpengaruh ke batas
/// `post_max_size` server dan ke jendela replay 30 detik gateway — foto perlu dikecilkan dulu.
Future<Uint8List> compressImageBytes(Uint8List bytes, {int maxSide = 0}) =>
    _impl.compressImageBytes(bytes, maxSide: maxSide);

Future<Uint8List> compressImageFile(String path) =>
    _impl.compressImageFile(path);
