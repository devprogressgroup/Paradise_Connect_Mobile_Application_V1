import 'dart:typed_data';

import 'image_compress_impl.dart'
    if (dart.library.html) 'image_compress_web.dart' as _impl;

Future<Uint8List> compressImageBytes(Uint8List bytes) =>
    _impl.compressImageBytes(bytes);

Future<Uint8List> compressImageFile(String path) =>
    _impl.compressImageFile(path);
