// Mobile/native: tidak perlu "memanaskan" izin kamera lebih dulu — permission
// flow native (geolocator_android/geolocator_apple, image_picker/camera plugin)
// tidak kena batasan user-gesture-window seperti getUserMedia() di browser.
Future<void> primeCameraPermission() async {}
