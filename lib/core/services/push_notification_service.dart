import 'dart:convert';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:progress_group/core/services/version_check_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/notif/presentation/state/received_notif_cubit.dart';
import 'package:progress_group/core/constants/attendance_feedback_labels.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/attendance_feedback_dialog.dart';
import 'package:progress_group/core/utils/widget/global_notification_dialog.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification.dart';

const String _channelId = 'upcoming_task_channel';
const String _channelName = 'Upcoming Tasks';

/// Menu internal app yang bisa dituju dari `link_url` Notifikasi Global (format
/// `app://<key>` atau `app://<key>?param=...`, key harus ada di map ini —
/// KECUALI `attendance` dan `contact_detail` yang butuh parameter tambahan,
/// ditangani terpisah di [PushNotificationService.tryNavigateInternalLink]) —
/// dibuat sama dengan dropdown "Menu Aplikasi" di dashboard
/// (GlobalNotificationController::INTERNAL_LINK_KEYS).
const Map<String, String> globalNotificationInternalRoutes = {
  'approval': '/attandance/approval',
  'contact': '/contact',
  'task_home': '/task-home',
  'sales_kit': '/sales-kit',
  'site_plan': '/site-plan',
  'pipeline': '/pipeline',
  'notif': '/notif',
  'profile': '/profile',
  'siap_huni': '/siap-huni',
};

const String _vapidKey =  'BGIeIvkhfZzClnpnsLcZLyggcadQqTf_g996DoCZ1hJGeLcd0Tn8gHHuUnmjhvFA62wHqFLVDLaJjmZeGHC95PQ';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =   FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static Dio? _dio;
  static AuthLocalDataSource? _authLocalDataSource;
  static RemoteMessage? _pendingMessage;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _supported = true;

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static final otaTrigger = ValueNotifier<VersionCheckResult?>(null);

  static void setDio(Dio dio) {
    _dio = dio;
  }

  static void setAuthLocalDataSource(AuthLocalDataSource authLocalDataSource) {
    _authLocalDataSource = authLocalDataSource;
  }

  static Future<void> checkAndShowUpdateBanner() async {
  
    try {
      final dio = _dio ?? Dio();
      final resp = await dio.get('/app-version');
      final data = resp.data['data'];
      final serverVersion = (data['version'] as String?)?.trim() ?? '';
      final downloadUrl   = (data['download_url'] as String?) ?? '';
      if (serverVersion.isEmpty) return;

      final info           = await PackageInfo.fromPlatform();
      final currentVersion = info.version.trim();

      if (!_isNewer(serverVersion, currentVersion)) return;

      ReceivedNotifCubit.receive(
        title: 'Versi baru tersedia',
        body: 'v$serverVersion tersedia untuk diunduh.',
        type: 'app_update',
        data: {'type': 'app_update', 'download_url': downloadUrl},
      );

      scaffoldMessengerKey.currentState
        ?..hideCurrentMaterialBanner()
        ..showMaterialBanner(
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            content: Text(
              'Versi baru tersedia: v$serverVersion',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
                },
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () {
                  scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
                  otaTrigger.value = VersionCheckResult(
                    requiresUpdate: true,
                    latestVersion: serverVersion,
                    currentVersion: currentVersion,
                    downloadUrl: downloadUrl,
                  );
                },
                child: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
    } catch (_) {}
  }

  static bool _isNewer(String a, String b) {
    final av = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bv = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = av.length > bv.length ? av.length : bv.length;
    for (int i = 0; i < len; i++) {
      final ai = i < av.length ? av[i] : 0;
      final bi = i < bv.length ? bv[i] : 0;
      if (ai > bi) return true;
      if (ai < bi) return false;
    }
    return false;
  }

  static void sendTokenAfterLogin() {
    if (!_supported) {
      _registerDevice(null);
      return;
    }
    _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null).then((token) {
      _sendTokenToBackend(token);
    }).catchError((e) {
      debugPrint('[FCM] getToken failed: $e');
      _registerDevice(null);
    });
  }

  static Future<void> initialize() async {
    try {
      // Di web, minta izin notifikasi harus dipicu oleh gesture user asli (klik) —
      // dipanggil otomatis di sini (sebelum runApp, tanpa gesture) bikin Chrome diam-diam
      // auto-deny permintaannya, dan di Safari malah bisa menggantung selamanya menunggu
      // gesture yang tidak pernah datang, memblokir seluruh app boot. Di web, permintaan
      // izin notifikasi sekarang didelegasikan ke DevicePermissionGate (tombol di layar gate).
      if (!kIsWeb) await _requestPermission();
    } catch (e) {
      debugPrint('[FCM] Browser tidak mendukung Firebase Messaging: $e');
      _supported = false;
      return;
    }
    if (!kIsWeb) await _setupLocalNotifications();
    if (kIsWeb) registerFcmServiceWorkerMessages(_handleServiceWorkerMessage);

    try {
      _messaging.onTokenRefresh.listen(_sendTokenToBackend);
      // onError di sini menangkap kegagalan konversi JS->Dart milik plugin sendiri
      // (mis. bug interop firebase_messaging_web pada payload push tertentu) yang lolos
      // dari try/catch di dalam _handleForegroundMessage karena terjadi sebelum RemoteMessage
      // selesai dibentuk, supaya tidak jadi uncaught error yang membekukan stream ini.
      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
        onError: (e, st) => debugPrint('[FCM] onMessage stream error: $e'),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationTap,
        onError: (e, st) => debugPrint('[FCM] onMessageOpenedApp stream error: $e'),
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingMessage = initialMessage;
      }
    } catch (e) {
      debugPrint('[FCM] Messaging listener setup failed: $e');
      _supported = false;
    }
  }

  static void processPendingMessage() {
    if (_pendingMessage != null) {
      final msg = _pendingMessage!;
      _pendingMessage = null;
      _navigateFromData(_safeData(msg));
    }
  }

  static void navigateFromData(Map<String, dynamic> data) => _navigateFromData(data);

  /// Cek apakah [linkUrl] adalah link internal (`app://<key>` atau
  /// `app://<key>?param=...`) dari Notifikasi Global. Kalau iya, langsung
  /// navigasi ke halaman terkait dan return true. Kalau bukan (link eksternal
  /// biasa/null/key tak dikenal), return false — caller yang buka via
  /// url_launcher seperti biasa.
  static bool tryNavigateInternalLink(String? linkUrl) {
    if (linkUrl == null || !linkUrl.startsWith('app://')) return false;
    final uri = Uri.tryParse(linkUrl);
    if (uri == null) return false;

    final key = uri.host;

    // Tab attandance (Clock In/Check In/Clock Out) dipilih lewat ?tab=, bukan
    // key terpisah — satu route '/attandance', beda initialTab saja.
    if (key == 'attendance') {
      final tab = _attendanceTabIndex(uri.queryParameters['tab']);
      AppRouter.router.go(tab == 0 ? '/attandance' : '/attandance?initialTab=$tab');
      return true;
    }

    // Detail SATU kontak spesifik (dipilih admin saat kirim notif) dibuka di
    // tab Activity/About/Attachment-nya — dataContact cuma butuh contactId,
    // detail lengkap di-fetch ulang sama ContactDetailPage sendiri lewat
    // ContactBloc (lihat _getContactDetail() di contact-detail/index.dart).
    if (key == 'contact_detail') {
      final contactId = int.tryParse(uri.queryParameters['contact_id'] ?? '');
      if (contactId == null) return false;
      final tab = _contactDetailTabIndex(uri.queryParameters['tab']);
      AppRouter.router.goNamed(
        'detailContact',
        extra: ContactDetailArgs(
          dataContact: ContactEntity(contactId: contactId),
          initialTab: tab,
        ),
      );
      return true;
    }

    final path = globalNotificationInternalRoutes[key];
    if (path == null) return false;

    AppRouter.router.go(path);
    return true;
  }

  /// Urutan tab AttandancePage: 0=Clock In, 1=Check In, 2=Clock Out
  /// (lihat `tabs` di attandance-page/index.dart).
  static int _attendanceTabIndex(String? tab) {
    switch (tab) {
      case 'activity':
        return 1; // Check In
      case 'log':
        return 2; // Clock Out
      default:
        return 0; // Clock In
    }
  }

  /// Urutan tab ContactDetailPage: 0=Activity, 1=About, 2=Attachment
  /// (lihat `tabs` di contact-detail/index.dart).
  static int _contactDetailTabIndex(String? tab) {
    switch (tab) {
      case 'about':
        return 1;
      case 'attachment':
        return 2;
      default:
        return 0; // activity
    }
  }

  // Pesan yang direlay oleh service worker (web/firebase-messaging-sw.js) lewat
  // postMessage saat notifikasi OS diklik. client.navigate() sebelumnya me-reload
  // seluruh app dari nol (itu penyebab notifikasi terasa lambat saat diklik) — sekarang
  // SW cukup fokuskan tab yang sudah terbuka lalu SPA-nya sendiri yang pindah halaman.
  static void _handleServiceWorkerMessage(String jsonMessage) {
    try {
      final msg = jsonDecode(jsonMessage) as Map<String, dynamic>;
      if (msg['type'] != 'fcm_notification_click') return;
      final data = (msg['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      _navigateFromData(data);
    } catch (e) {
      debugPrint('[FCM] gagal memproses pesan dari service worker: $e');
    }
  }

  // firebase_messaging_web kadang mengembalikan RemoteMessage.data yang bukan Map Dart
  // asli (masih objek JS mentah dari interop), sehingga indexing biasa (data['x']) bisa
  // lempar "TypeError: map[$_get] is not a function" dan memutus alur sebelum dialog notifikasi
  // sempat tampil. Bungkus konversinya supaya gagal dengan aman ke map kosong, bukan crash.
  static Map<String, dynamic> _safeData(RemoteMessage message) {
    try {
      return Map<String, dynamic>.from(message.data);
    } catch (e) {
      debugPrint('[FCM] gagal membaca data notifikasi: $e');
      return <String, dynamic>{};
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final data = details.payload != null
            ? Map<String, dynamic>.from(jsonDecode(details.payload!) as Map)
            : <String, dynamic>{};
        _navigateFromData(data);
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi untuk upcoming task hari ini',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  static Future<void> _sendTokenToBackend(String? token) async {
    if (_dio != null && token != null && token.isNotEmpty) {
      try {
        await _dio!.post('/fcm-token', data: {
          'fcm_token': token,
          'platform': kIsWeb ? 'web' : 'mobile',
        });
      } catch (_) {}
    }
    await _registerDevice(token);
  }

  static Future<String> _getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceUuid = prefs.getString('device_uuid');
    if (deviceUuid == null || deviceUuid.isEmpty) {
      deviceUuid = const Uuid().v4();
      await prefs.setString('device_uuid', deviceUuid);
    }
    return deviceUuid;
  }

  static Future<Map<String, dynamic>> _buildDevicePayload(String? fcmToken) async {
    final deviceUuid = await _getOrCreateDeviceUuid();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    var platform = 'web';
    var brand = '';
    var manufacturer = '';
    var model = '';
    var deviceName = '';
    var osName = 'Web';
    var osVersion = '';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        final ua = webInfo.userAgent ?? '';
        brand = webInfo.browserName.name;
        manufacturer = webInfo.vendor ?? '';
        deviceName = webInfo.browserName.name;

        final rawPlatform = webInfo.platform ?? '';
        osName = rawPlatform.contains('Win')
            ? 'Windows'
            : rawPlatform.contains('Mac')
                ? 'macOS'
                : rawPlatform.contains('Linux')
                    ? 'Linux'
                    : rawPlatform.isNotEmpty
                        ? rawPlatform
                        : 'Web';

        final browserVersion = RegExp(r'(Chrome|Firefox|Edg|OPR|Version)/([\d.]+)').firstMatch(ua)?.group(2) ?? '';
        model = '${webInfo.browserName.name} $browserVersion'.trim();

        final winVersion = RegExp(r'Windows NT ([\d.]+)').firstMatch(ua)?.group(1);
        final macVersion = RegExp(r'Mac OS X ([\d_.]+)').firstMatch(ua)?.group(1)?.replaceAll('_', '.');
        osVersion = winVersion ?? macVersion ?? '';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'android';
        brand = androidInfo.brand;
        manufacturer = androidInfo.manufacturer;
        model = androidInfo.model;
        deviceName = androidInfo.device;
        osName = 'Android';
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'ios';
        brand = 'Apple';
        manufacturer = 'Apple';
        model = iosInfo.utsname.machine;
        deviceName = iosInfo.name;
        osName = 'iOS';
        osVersion = iosInfo.systemVersion;
      }
    } catch (e) {
      debugPrint('[Devices] gagal membaca device info: $e');
    }

    final activeToken = await _authLocalDataSource?.getToken();

    String truncate(String s, int max) => s.length > max ? s.substring(0, max) : s;

    return {
      'device_uuid': deviceUuid,
      'platform': platform,
      'brand': truncate(brand, 100),
      'manufacturer': truncate(manufacturer, 100),
      'model': truncate(model, 100),
      'device_name': truncate(deviceName, 100),
      'os_name': truncate(osName, 50),
      'os_version': truncate(osVersion, 50),
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'fcm_token': kIsWeb ? null : fcmToken,
      'web_fcm_token': kIsWeb ? fcmToken : null,
      'active_token': activeToken,
    };
  }

  static Future<void> _registerDevice(String? fcmToken) async {
    if (_dio == null) return;
    try {
      final payload = await _buildDevicePayload(fcmToken);
      await _dio!.post('/devices', data: payload);
    } catch (e) {
      debugPrint('[Devices] register failed: $e');
    }
  }

  static void _showWebBanner(String? title, String? body, {VoidCallback? onTap}) {
    if (title == null) return;
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body != null && body.isNotEmpty) Text(body),
          ],
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: onTap != null
            ? SnackBarAction(
                label: 'Lihat',
                textColor: Color(amberMaterialColor),
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onTap();
                },
              )
            : null,
      ),
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final data = _safeData(message);

    if (data['type'] == 'attendance_feedback') {
      _showDialogAfterFrame(() => _showAttendanceFeedbackDialog(data));
      return;
    }

    if (data['type'] == 'global_notification') {
      _showDialogAfterFrame(() => _showGlobalNotificationDialogFromData(data));
      return;
    }

    final notification = message.notification;

    if (kIsWeb) {
      final title = notification?.title ?? data['title'] as String?;
      final body  = notification?.body  ?? data['body']  as String?;
      final onTap = () => _navigateFromData(data);
      _showWebBanner(title, body, onTap: onTap);
      showWebNotification(title, body);
      return;
    }

    if (notification == null) return;

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi untuk upcoming task hari ini',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = _safeData(message);
    _navigateFromData(data);
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final action = data['action'] as String?;

    if (type == 'app_update') {
      final url = data['download_url'] as String? ?? data['route'] as String?;
      if (url != null && url.isNotEmpty) {
        PackageInfo.fromPlatform().then((info) {
          otaTrigger.value = VersionCheckResult(
            requiresUpdate: true,
            latestVersion: (data['version'] as String?) ?? '',
            currentVersion: info.version,
            downloadUrl: url,
          );
        });
      }
      return;
    }

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    if (type == 'attendance') {
      int tab = 0;
      if (action == 'clock_out') {
        tab = 2;
      } else if (action == 'checkin_activity') {
        tab = 1;
      }
      AppRouter.router.go('/attandance?initialTab=$tab');
      return;
    }

    if (type == 'approval_pending' || type == 'attendance_null_location') {
      AppRouter.router.goNamed('approval');
      return;
    }

    if (type == 'attendance_approved' || type == 'attendance_rejected') {
      AppRouter.router.go('/attandance');
      return;
    }

    // Dikirim ContactLifecycleController::notifyResignReplacement() — kontak yang baru
    // dialihkan (resign perorangan/team) muncul di list Contact milik sales pengganti.
    if (type == 'contact_resign_team') {
      AppRouter.router.go('/contact');
      return;
    }

    if (type == 'attendance_feedback') {
      _showDialogAfterFrame(() => _showAttendanceFeedbackDialog(data));
      return;
    }

    if (type == 'global_notification') {
      _showDialogAfterFrame(() => _showGlobalNotificationDialogFromData(data));
      return;
    }

    if (type == 'upcoming_task') {
      final activityIdStr = data['activity_id'] as String?;
      final contactIdStr  = data['contact_id'] as String?;
      final activityId    = activityIdStr != null ? int.tryParse(activityIdStr) : null;
      final contactId     = contactIdStr  != null ? int.tryParse(contactIdStr)  : null;

      if (activityId != null && contactId != null) {
        final activityType   = data['activity_type']       as String? ?? '';
        final contactName    = data['contact_name']        as String? ?? '';
        final activityDate   = data['activity_date']       as String? ?? AppTime.now().toIso8601String().substring(0, 10);
        final nextFollowUp   = data['next_follow_up_date'] as String?;
        final createdBy      = int.tryParse(data['created_by'] as String? ?? '') ?? 0;
        final createdAt      = data['created_at']          as String? ?? AppTime.now().toIso8601String();

        int    page     = 6;
        String namePage = 'Update Status Prospect';
        final  t        = activityType.toLowerCase();
        if      (t.contains('call'))      { page = 0; namePage = 'Call'; }
        else if (t.contains('whatsapp'))  { page = 1; namePage = 'WhatsApp'; }
        else if (t.contains('meeting'))   { page = 2; namePage = 'Meeting'; }
        else if (t.contains('task'))      { page = 3; namePage = 'Task'; }
        else if (t.contains('visit'))     { page = 4; namePage = 'Visit'; }

        AppRouter.router.goNamed(
          'addContact',
          extra: ContactDetailArgs(
            page: page,
            namePage: namePage,
            buttonLabel: 'Complete',
            dataActivity: ActivityEntity(
              activityId:        activityId,
              contactId:         contactId,
              activityType:      activityType,
              activityDate:      activityDate,
              nextFollowUpDate:  nextFollowUp,
              createdBy:         createdBy,
              createdAt:         createdAt,
              contactName:       contactName,
            ),
            dataContact: ContactEntity(
              contactId: contactId,
              fullName:  contactName,
            ),
          ),
        );
        return;
      }
    }

    AppRouter.router.go('/task-home');
  }

  /// Tunda pemanggilan [action] sampai frame yang sedang berjalan selesai. showDialog yang
  /// dipanggil langsung dari callback async (listener FCM, dsb.) bisa beradu dengan siklus
  /// build/layout Flutter saat ini — hasilnya cuma barrier gelap muncul tanpa isi dialog.
  /// addPostFrameCallback memastikan dialog di-push setelah frame saat ini benar-benar selesai.
  static void _showDialogAfterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  static Future<void> _showAttendanceFeedbackDialog(Map<String, dynamic> data) async {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // Device yang sama bisa saja pernah dipakai login user lain (fcm_token ke-reuse di HP
    // testing/shared) — pastikan notifikasi ini memang untuk user yang SEDANG login sebelum
    // ditampilkan, jangan asal percaya token yang menerima push-nya.
    final targetUserId = data['user_id']?.toString();
    if (targetUserId != null && targetUserId.isNotEmpty) {
      final currentUserId = await _currentUserId();
      if (currentUserId != null && currentUserId != targetUserId) {
        return;
      }
    }

    final logId = int.tryParse(data['log_id']?.toString() ?? '');
    final isOk = data['verdict']?.toString() == '1';
    final categoryLabels = (data['categories']?.toString() ?? '')
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .map((c) => attendanceFeedbackCategoryLabels[c] ?? c)
        .toList();
    final note = data['note']?.toString() ?? '';
    final photoUrl = data['photo_url']?.toString() ?? '';

    showAttendanceFeedbackDialog(
      context,
      isOk: isOk,
      categoryLabels: categoryLabels,
      note: note,
      photoUrl: photoUrl,
      onAcknowledge: () {
        if (logId != null) _acknowledgeFeedback(logId);
        AppRouter.router.go('/attandance');
      },
    );
  }

  static Future<void> _acknowledgeFeedback(int logId) async {
    try {
      await _dio?.post('/attendance/feedback/ack', data: {'log_id': logId});
    } catch (_) {}
  }

  /// Ambil user_id dari klaim `uid` di JWT yang sedang tersimpan (tanpa perlu call API) —
  /// dipakai buat validasi bahwa notifikasi yang sampai di device ini memang untuk user
  /// yang sekarang login.
  static Future<String?> _currentUserId() async {
    try {
      final token = await _authLocalDataSource?.getToken();
      if (token == null || token.isEmpty) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return (map['uid'] ?? map['sub'])?.toString();
    } catch (_) {
      return null;
    }
  }

  static void _showGlobalNotificationDialogFromData(Map<String, dynamic> data) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showGlobalNotificationDialog(
      context,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      mediaType: data['media_type']?.toString(),
      mediaUrl: data['media_url']?.toString(),
      linkUrl: data['link_url']?.toString(),
    );
  }
}
