import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Stub mobile — kamera native dipakai lewat `image_picker`, halaman ini hanya untuk web.
class WebCameraCapture {
  static Future<Uint8List?> open(
    BuildContext context, {
    double? maxDimension,
    int? quality,
  }) async => null;
}
