import 'dart:js_interop';

@JS('forcePwaUpdate')
external void _forcePwaUpdate();

void forcePwaUpdate() {
  try {
    _forcePwaUpdate();
  } catch (_) {}
}
