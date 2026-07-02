import 'camera_permission_primer_impl.dart'
    if (dart.library.html) 'camera_permission_primer_web.dart' as _impl;

/// Minta izin kamera SECEPAT MUNGKIN setelah user tap, sebelum proses lokasi
/// yang panjang (cek GPS, request permission lokasi, load office locations,
/// dst). WebKit (Safari) berhenti menganggap sebuah permintaan izin berasal
/// dari user gesture begitu sudah lewat beberapa await/waktu sejak tap-nya —
/// setelah itu getUserMedia() diam-diam ditolak TANPA menampilkan dialog izin
/// sama sekali. Panggil ini di awal alur (index.dart _handleMoveCamera)
/// supaya izin kamera sudah "dipanaskan" duluan, sebelum jendela user-gesture
/// itu habis. No-op di platform non-web (mobile pakai native permission flow).
Future<void> primeCameraPermission() => _impl.primeCameraPermission();
