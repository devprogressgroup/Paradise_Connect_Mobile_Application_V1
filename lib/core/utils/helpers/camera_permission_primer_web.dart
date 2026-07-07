
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
