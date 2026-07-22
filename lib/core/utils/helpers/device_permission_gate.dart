import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:progress_group/core/services/ota_update_service.dart';
import 'camera_permission_primer.dart';

enum DevicePermissionType { camera, gallery, location, contacts, notification, installPackages }

class DevicePermissionItem {
  final DevicePermissionType type;
  final String label;
  final String description;

  const DevicePermissionItem({
    required this.type,
    required this.label,
    required this.description,
  });
}

/// Gate izin perangkat (kamera, galeri, lokasi, kontak, notifikasi) yang wajib
/// diberikan sebelum aplikasi bisa dipakai. Terpisah dari [PermissionsHelper]
/// yang mengatur hak akses fitur berbasis role dari backend.
class DevicePermissionGate {
  DevicePermissionGate._();

  static const _items = [
    DevicePermissionItem(
      type: DevicePermissionType.camera,
      label: 'Kamera',
      description: 'Untuk mengambil foto absensi atau dokumen',
    ),
    DevicePermissionItem(
      type: DevicePermissionType.gallery,
      label: 'Galeri / Foto',
      description: 'Untuk memilih foto atau file dari galeri',
    ),
    DevicePermissionItem(
      type: DevicePermissionType.location,
      label: 'Lokasi',
      description: 'Untuk mencatat lokasi saat melakukan absensi',
    ),
    DevicePermissionItem(
      type: DevicePermissionType.contacts,
      label: 'Kontak',
      description: 'Untuk mengisi data kontak otomatis dari buku kontak',
    ),
    DevicePermissionItem(
      type: DevicePermissionType.notification,
      label: 'Notifikasi',
      description: 'Untuk menerima notifikasi tugas, approval, dan update',
    ),
    DevicePermissionItem(
      type: DevicePermissionType.installPackages,
      label: 'Instal Pembaruan Aplikasi',
      description: 'Supaya update aplikasi versi terbaru bisa langsung dipasang tanpa diminta lagi nanti',
    ),
  ];

  /// Kontak tidak tersedia di web (flutter_contacts mobile-only), dan galeri
  /// di web ditangani file picker browser tanpa izin OS terpisah, jadi keduanya
  /// tidak di-gate di web. Instal pembaruan (APK sideload) cuma konsep Android,
  /// jadi tidak relevan di web maupun iOS. Kamera DI-gate di web juga (lewat
  /// getUserMedia, lihat [request]) supaya diminta di awal sekali di gate ini,
  /// bukan mendadak nanti pas user pertama kali buka kamera absensi.
  static List<DevicePermissionItem> requiredItems() {
    if (kIsWeb) {
      return _items
          .where((i) =>
              i.type == DevicePermissionType.camera ||
              i.type == DevicePermissionType.location ||
              i.type == DevicePermissionType.notification)
          .toList();
    }
    if (!Platform.isAndroid) {
      return _items.where((i) => i.type != DevicePermissionType.installPackages).toList();
    }
    return _items;
  }

  /// Safari (terutama iOS, dan Web Push umumnya butuh PWA terinstal) kadang tidak
  /// pernah menyelesaikan promise dari geolocator/firebase_messaging web interop
  /// (API tidak didukung, service worker tidak pernah teregistrasi, dst) alih-alih
  /// melempar error — tanpa guard ini, gate permission bisa macet selamanya di
  /// loading spinner. Timeout + fallback memastikan `_refresh()` di halaman gate
  /// selalu selesai, browser mana pun.
  static Future<T> _guard<T>(
    Future<T> Function() action,
    T fallback, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await action().timeout(timeout);
    } catch (_) {
      return fallback;
    }
  }

  static Future<bool> isLocationServiceEnabled() {
    return _guard(() => Geolocator.isLocationServiceEnabled(), true);
  }

  static int? _androidSdkInt;

  static Future<int> _getAndroidSdkInt() async {
    return _androidSdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  }

  /// READ_MEDIA_IMAGES ([ph.Permission.photos]) baru ada mulai Android 13 (Tiramisu).
  /// Di bawah itu, permission_handler tidak punya nama permission untuk di-mapping,
  /// sehingga status-nya selalu "denied" TANPA pernah menampilkan dialog izin —
  /// item galeri jadi macet permanen. Pakai READ_EXTERNAL_STORAGE ([ph.Permission.storage])
  /// sebagai gantinya di Android <13 supaya benar-benar bisa direquest dan diizinkan.
  static Future<ph.Permission> _galleryPermission() async {
    if (kIsWeb || !Platform.isAndroid) return ph.Permission.photos;
    final sdkInt = await _getAndroidSdkInt();
    return sdkInt >= 33 ? ph.Permission.photos : ph.Permission.storage;
  }

  /// Diisi [primeWebCamera] setelah getUserMedia sukses — dipakai [isGranted] sebagai
  /// fallback di browser yang tidak mendukung query Permissions API 'camera' (Safari, Firefox).
  static bool _webCameraGranted = false;

  static Future<bool> isGranted(DevicePermissionType type) async {
    switch (type) {
      case DevicePermissionType.location:
        return _guard(() async {
          if (!await Geolocator.isLocationServiceEnabled()) return false;
          final status = await Geolocator.checkPermission();
          return status == LocationPermission.always ||
              status == LocationPermission.whileInUse;
        }, false);
      case DevicePermissionType.notification:
        if (kIsWeb) {
          // Fail-open: notifikasi bukan syarat mutlak jalannya app, dan Safari (khususnya
          // iOS di luar PWA terinstal) tidak selalu mendukung Web Push — kalau checknya
          // gagal/timeout, jangan sampai user Safari terkunci permanen di gate ini.
          return _guard(() async {
            final settings = await FirebaseMessaging.instance.getNotificationSettings();
            return settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;
          }, true);
        }
        return (await ph.Permission.notification.status).isGranted;
      case DevicePermissionType.camera:
        if (kIsWeb) {
          // Permissions API 'camera' cuma dikenal browser Chromium — di Safari/Firefox
          // query-nya balas null (unsupported). Kalau begitu, andalkan _webCameraGranted
          // (diisi [primeWebCamera] setelah getUserMedia sukses) alih-alih selalu bilang
          // "belum" — tanpa ini, tap "Izinkan" sukses tapi _refresh() sesudahnya bilang
          // tetap belum granted, dan gate ini macet permanen walau user sudah mengizinkan.
          return _guard(() async {
            final state = await queryCameraPermissionState();
            return state == null ? _webCameraGranted : state == 'granted';
          }, _webCameraGranted);
        }
        return (await ph.Permission.camera.status).isGranted;
      case DevicePermissionType.gallery:
        if (kIsWeb) return true;
        final status = await (await _galleryPermission()).status;
        // Android 14+ ("Pilih foto tertentu") dan iOS (limited photo library) melaporkan
        // status limited, bukan granted, walau user sudah mengizinkan akses parsial —
        // itu tetap cukup buat fitur upload foto di app ini.
        return status.isGranted || status.isLimited;
      case DevicePermissionType.contacts:
        if (kIsWeb) return true;
        return (await ph.Permission.contacts.status).isGranted;
      case DevicePermissionType.installPackages:
        return OtaUpdateService.canInstallPackages();
    }
  }

  static Future<bool> isPermanentlyDenied(DevicePermissionType type) async {
    if (kIsWeb) {
      // Browser tidak punya "buka pengaturan app" via JS — begitu user klik Block di
      // dialog native browser, statusnya permanen sampai user ubah manual lewat site
      // settings browser. Location, notification, dan kamera (lewat Permissions API,
      // kalau didukung) yang bisa dideteksi (lihat toLocationPermission di geolocator_web:
      // browser state 'denied' → deniedForever).
      switch (type) {
        case DevicePermissionType.location:
          return _guard(
            () async => await Geolocator.checkPermission() == LocationPermission.deniedForever,
            false,
          );
        case DevicePermissionType.notification:
          return _guard(() async {
            final settings = await FirebaseMessaging.instance.getNotificationSettings();
            return settings.authorizationStatus == AuthorizationStatus.denied;
          }, false);
        case DevicePermissionType.camera:
          return _guard(() async => await queryCameraPermissionState() == 'denied', false);
        case DevicePermissionType.gallery:
        case DevicePermissionType.contacts:
        case DevicePermissionType.installPackages:
          return false;
      }
    }
    switch (type) {
      case DevicePermissionType.location:
        return _guard(
          () async => await Geolocator.checkPermission() == LocationPermission.deniedForever,
          false,
        );
      case DevicePermissionType.notification:
        return (await ph.Permission.notification.status).isPermanentlyDenied;
      case DevicePermissionType.camera:
        return (await ph.Permission.camera.status).isPermanentlyDenied;
      case DevicePermissionType.gallery:
        return (await (await _galleryPermission()).status).isPermanentlyDenied;
      case DevicePermissionType.contacts:
        return (await ph.Permission.contacts.status).isPermanentlyDenied;
      case DevicePermissionType.installPackages:
        // Bukan runtime permission dialog biasa — tidak ada state "ditolak permanen",
        // cuma toggle di halaman Settings khusus yang dibuka lewat request().
        return false;
    }
  }

  static Future<bool> request(DevicePermissionType type) async {
    switch (type) {
      case DevicePermissionType.location:
        if (!await Geolocator.isLocationServiceEnabled()) return false;
        var status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied) {
          status = await Geolocator.requestPermission();
        }
        return status == LocationPermission.always ||
            status == LocationPermission.whileInUse;
      case DevicePermissionType.notification:
        if (kIsWeb) {
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          return settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        }
        return (await ph.Permission.notification.request()).isGranted;
      case DevicePermissionType.camera:
        if (kIsWeb) return primeWebCamera();
        return (await ph.Permission.camera.request()).isGranted;
      case DevicePermissionType.gallery:
        if (kIsWeb) return true;
        final status = await (await _galleryPermission()).request();
        return status.isGranted || status.isLimited;
      case DevicePermissionType.contacts:
        if (kIsWeb) return true;
        return (await ph.Permission.contacts.request()).isGranted;
      case DevicePermissionType.installPackages:
        // Tidak ada dialog — satu-satunya cara adalah buka halaman Settings khusus dan
        // menunggu user kembali (lifecycle resumed di halaman gate akan re-check statusnya).
        await OtaUpdateService.openInstallPermissionSettings();
        return OtaUpdateService.canInstallPackages();
    }
  }

  static Future<void> openLocationServiceSettings() {
    return Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    if (kIsWeb) return;
    await ph.openAppSettings();
  }

  /// Backing implementation [request] untuk kamera di web — getUserMedia adalah satu-satunya
  /// cara memicu dialog izin kamera yang didukung semua browser (lihat [isGranted]/
  /// [isPermanentlyDenied] soal Permissions API 'camera' yang cuma dikenal Chromium).
  static Future<bool> primeWebCamera() async {
    if (!kIsWeb) return true;
    final granted = await requestCameraPermissionWeb();
    if (granted) _webCameraGranted = true;
    return granted;
  }
}
