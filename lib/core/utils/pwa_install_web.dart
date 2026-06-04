import 'dart:js_interop';

@JS('isPwaInstallAvailable')
external bool _isPwaInstallAvailable();

@JS('showPwaInstallPrompt')
external bool _showPwaInstallPrompt();

bool isPwaInstallAvailable() {
  try {
    return _isPwaInstallAvailable();
  } catch (_) {
    return false;
  }
}

Future<void> showPwaInstallPrompt() async {
  try {
    _showPwaInstallPrompt();
  } catch (_) {}
}
