import 'camera_permission_primer_impl.dart'
    if (dart.library.html) 'camera_permission_primer_web.dart' as _impl;

Future<void> primeCameraPermission() => _impl.primeCameraPermission();
