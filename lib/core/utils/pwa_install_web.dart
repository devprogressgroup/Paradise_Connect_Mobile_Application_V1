import 'dart:js_interop';

@JS('isPwaInstallAvailable')
external bool _isPwaInstallAvailable();

@JS('showPwaInstallPrompt')
external bool _showPwaInstallPrompt();

@JS('isPwaRunningStandalone')
external bool _isPwaRunningStandalone();

@JS('registerPwaCallbacks')
external void _registerPwaCallbacks(JSFunction onAvailable, JSFunction onInstalled);

bool isPwaInstallAvailable() {
  try { return _isPwaInstallAvailable(); } catch (_) { return false; }
}

bool isPwaRunningStandalone() {
  try { return _isPwaRunningStandalone(); } catch (_) { return false; }
}

Future<void> showPwaInstallPrompt() async {
  try { _showPwaInstallPrompt(); } catch (_) {}
}

void registerPwaCallbacks({required void Function() onAvailable, required void Function() onInstalled}) {
  try {
    _registerPwaCallbacks(
      onAvailable.toJS,
      onInstalled.toJS,
    );
  } catch (_) {}
}
