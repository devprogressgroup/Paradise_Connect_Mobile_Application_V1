import 'package:flutter/foundation.dart';

/// Id kartu Wall of Fame yang harus disorot di Home. Diisi saat notifikasi pemenang di-tap,
/// lalu dikosongkan oleh Home setelah kartunya di-scroll.
class FameFocus {
  FameFocus._();

  static final ValueNotifier<int?> cardId = ValueNotifier<int?>(null);
}
