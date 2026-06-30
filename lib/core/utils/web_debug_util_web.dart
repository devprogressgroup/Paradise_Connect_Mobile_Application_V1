import 'dart:js_interop';

@JS('showDebugPanel')
external void _jsShowDebugPanel();

@JS('logDebugLine')
external void _jsLogDebugLine(String type, String msg);

void showDebugPanel() {
  try { _jsShowDebugPanel(); } catch (_) {}
}

void logDebugError(String message) {
  try { _jsLogDebugLine('error', message); } catch (_) {}
}

void logDebugInfo(String message) {
  try { _jsLogDebugLine('log', message); } catch (_) {}
}
