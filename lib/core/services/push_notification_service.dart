import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:progress_group/core/services/version_check_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/notif/presentation/state/received_notif_cubit.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification.dart';

const String _channelId = 'upcoming_task_channel';
const String _channelName = 'Upcoming Tasks';
const String _vapidKey =  'BGIeIvkhfZzClnpnsLcZLyggcadQqTf_g996DoCZ1hJGeLcd0Tn8gHHuUnmjhvFA62wHqFLVDLaJjmZeGHC95PQ';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =   FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static Dio? _dio;
  static RemoteMessage? _pendingMessage;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // false jika browser tidak mendukung Firebase Messaging (Chrome iOS, Safari lama)
  static bool _supported = true;

  /// Key untuk menampilkan SnackBar dari luar widget tree (web foreground notif).
  /// Pasang ke MaterialApp.scaffoldMessengerKey di main.dart.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Diset saat user tap "Download" di banner → main.dart dengarkan dan tampilkan UpdateScreen.
  static final otaTrigger = ValueNotifier<VersionCheckResult?>(null);

  /// Dipanggil setelah DioClient dibuat (di build() MyApp) agar token bisa dikirim ke backend.
  static void setDio(Dio dio) {
    _dio = dio;
  }

  /// Cek versi app ke server. Jika ada update → tampil banner di atas layar.
  static Future<void> checkAndShowUpdateBanner() async {
    if (kIsWeb) return; // hanya mobile
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

  /// Bandingkan versi semantic (major.minor.patch). Return true jika [a] > [b].
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

  /// Dipanggil setelah login berhasil — saat itu auth token sudah ada
  static void sendTokenAfterLogin() {
    if (!_supported) return;
    _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null).then((token) {
      if (token != null) _sendTokenToBackend(token);
    }).catchError((e) {
      debugPrint('[FCM] getToken failed: $e');
    });
  }

  /// Dipanggil sekali di main() setelah Firebase.initializeApp().
  static Future<void> initialize() async {
    try {
      await _requestPermission();
    } catch (e) {
      debugPrint('[FCM] Browser tidak mendukung Firebase Messaging: $e');
      _supported = false;
      return;
    }
    if (!kIsWeb) await _setupLocalNotifications();

    try {
      _messaging.onTokenRefresh.listen(_sendTokenToBackend);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingMessage = initialMessage;
      }
    } catch (e) {
      debugPrint('[FCM] Messaging listener setup failed: $e');
      _supported = false;
    }
  }

  /// Dipanggil dari initState() MyApp via addPostFrameCallback agar navigator sudah siap.
  static void processPendingMessage() {
    if (_pendingMessage != null) {
      final msg = _pendingMessage!;
      _pendingMessage = null;
      _saveToNotifList(msg);
      _navigateFromData(msg.data);
    }
  }

  /// Public wrapper untuk navigasi dari tap item di NotifPage.
  static void navigateFromData(Map<String, dynamic> data) => _navigateFromData(data);

  static void _saveToNotifList(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] as String? ?? '';
    final body  = message.notification?.body  ?? message.data['body']  as String? ?? '';
    final type  = message.data['type'] as String?;
    if (title.isEmpty && body.isEmpty) return;
    ReceivedNotifCubit.receive(title: title, body: body, type: type, data: message.data);
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
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

    // Buat notification channel untuk Android 8+
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


  static Future<void> _sendTokenToBackend(String token) async {
    if (_dio == null) return;
    try {
      await _dio!.post('/fcm-token', data: {
        'fcm_token': token,
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (_) {}
  }

  /// Tampilkan in-app SnackBar di web — selalu muncul meski tab sedang fokus.
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
                textColor: Colors.amber,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onTap();
                },
              )
            : null,
      ),
    );
  }

  // Tampilkan local notification saat app di foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    _saveToNotifList(message);

    final notification = message.notification;

    if (kIsWeb) {
      final title = notification?.title ?? message.data['title'] as String?;
      final body  = notification?.body  ?? message.data['body']  as String?;
      final onTap = () => _navigateFromData(message.data);
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
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _saveToNotifList(message);
    _navigateFromData(message.data);
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final action = data['action'] as String?;

    // app_update tidak butuh navigator context — cukup trigger ValueNotifier
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

    if (type == 'upcoming_task') {
      final activityIdStr = data['activity_id'] as String?;
      final contactIdStr  = data['contact_id'] as String?;
      final activityId    = activityIdStr != null ? int.tryParse(activityIdStr) : null;
      final contactId     = contactIdStr  != null ? int.tryParse(contactIdStr)  : null;

      if (activityId != null && contactId != null) {
        final activityType   = data['activity_type']       as String? ?? '';
        final contactName    = data['contact_name']        as String? ?? '';
        final activityDate   = data['activity_date']       as String? ?? DateTime.now().toIso8601String().substring(0, 10);
        final nextFollowUp   = data['next_follow_up_date'] as String?;
        final createdBy      = int.tryParse(data['created_by'] as String? ?? '') ?? 0;
        final createdAt      = data['created_at']          as String? ?? DateTime.now().toIso8601String();

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
}
