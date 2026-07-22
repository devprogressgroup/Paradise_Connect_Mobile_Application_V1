import 'camera_permission_primer_impl.dart'
    if (dart.library.html) 'camera_permission_primer_web.dart' as _impl;

Future<void> primeCameraPermission() => _impl.primeCameraPermission();

/// Sama seperti [primeCameraPermission], tapi melaporkan hasilnya (granted/tidak) alih-alih
/// menelan semua error — dipakai [DevicePermissionGate] untuk request kamera sebagai item
/// ter-gate di web, bukan cuma priming best-effort.
Future<bool> requestCameraPermissionWeb() => _impl.requestCameraPermissionWeb();

/// Status izin kamera browser lewat Permissions API, kalau didukung. Null kalau browser
/// tidak mendukung query 'camera' (Safari, Firefox) atau query-nya gagal.
Future<String?> queryCameraPermissionState() => _impl.queryCameraPermissionState();
