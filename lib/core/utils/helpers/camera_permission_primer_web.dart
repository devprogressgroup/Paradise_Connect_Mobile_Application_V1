// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Minta getUserMedia() sesaat, langsung matikan stream-nya lagi — tujuannya
/// cuma memicu dialog izin kamera browser SEDEKAT MUNGKIN dengan tap user,
/// sebelum proses lokasi yang panjang bikin WebKit anggap ini bukan lagi
/// permintaan dari user gesture. Halaman kamera (camera/index_stub.dart) tetap
/// akan memanggil getUserMedia() lagi nanti seperti biasa — kalau izin sudah
/// diberikan di sini, panggilan itu akan langsung sukses tanpa prompt ulang.
Future<void> primeCameraPermission() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return;
    final stream = await mediaDevices.getUserMedia({
      'video': {'facingMode': 'user'},
      'audio': false,
    }).timeout(const Duration(seconds: 10));
    stream.getTracks().forEach((t) => t.stop());
  } catch (_) {
    // Biarkan halaman kamera yang nanti nampilin error state-nya sendiri
    // (sudah lengkap di camera/index_stub.dart) kalau izin memang ditolak.
  }
}
