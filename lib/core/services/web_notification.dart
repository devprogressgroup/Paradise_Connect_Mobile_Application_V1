import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Notification')
extension type _JSNotification._(JSObject _) implements JSObject {
  external factory _JSNotification(String title, JSObject options);
  external static String get permission;
}

Future<void> showWebNotification(String? title, String? body) async {
  if (title == null) return;
  if (_JSNotification.permission == 'granted') {
    final options = JSObject();
    options.setProperty('body'.toJS, (body ?? '').toJS);
    _JSNotification(title, options);
  }
}
