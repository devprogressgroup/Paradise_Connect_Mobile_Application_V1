
import 'dart:async';
import 'dart:html' as html;

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
  }
}

/// getUserMedia adalah satu-satunya cara memicu dialog izin kamera yang didukung SEMUA
/// browser (Permissions API 'camera' cuma dikenal Chromium) — dipakai juga untuk MENGETAHUI
/// hasilnya (granted/denied), beda dengan [primeCameraPermission] yang menelan semua error.
Future<bool> requestCameraPermissionWeb() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return false;
    final stream = await mediaDevices.getUserMedia({
      'video': {'facingMode': 'user'},
      'audio': false,
    }).timeout(const Duration(seconds: 10));
    stream.getTracks().forEach((t) => t.stop());
    return true;
  } catch (_) {
    return false;
  }
}

Future<String?> queryCameraPermissionState() async {
  try {
    final permissions = html.window.navigator.permissions;
    if (permissions == null) return null;
    final status = await permissions.query({'name': 'camera'});
    return status.state;
  } catch (_) {
    return null;
  }
}
