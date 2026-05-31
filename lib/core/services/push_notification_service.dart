import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification.dart';

const String _channelId = 'upcoming_task_channel';
const String _channelName = 'Upcoming Tasks';
const String _vapidKey =
    'BGIeIvkhfZzClnpnsLcZLyggcadQqTf_g996DoCZ1hJGeLcd0Tn8gHHuUnmjhvFA62wHqFLVDLaJjmZeGHC95PQ';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PushNotificationService {
  static Dio? _dio;
  static RemoteMessage? _pendingMessage;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Key untuk menampilkan SnackBar dari luar widget tree (web foreground notif).
  /// Pasang ke MaterialApp.scaffoldMessengerKey di main.dart.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Dipanggil setelah DioClient dibuat (di build() MyApp) agar token bisa dikirim ke backend.
  static void setDio(Dio dio) {
    _dio = dio;
    _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null).then((token) {
      if (token != null) _sendTokenToBackend(token);
    });
  }

  /// Dipanggil sekali di main() setelah Firebase.initializeApp().
  static Future<void> initialize() async {
    await _requestPermission();
    if (!kIsWeb) await _setupLocalNotifications();
    await _registerToken();

    _messaging.onTokenRefresh.listen(_sendTokenToBackend);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Simpan pesan awal jika app dibuka dari notifikasi (saat app terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingMessage = initialMessage;
    }
  }

  /// Dipanggil dari initState() MyApp via addPostFrameCallback agar navigator sudah siap.
  static void processPendingMessage() {
    if (_pendingMessage != null) {
      _navigateFromData(_pendingMessage!.data);
      _pendingMessage = null;
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
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

  static Future<void> _registerToken() async {
    try {
      debugPrint('[FCM] Requesting token, kIsWeb=$kIsWeb');
      final token = await _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null);
      debugPrint('[FCM] Token: $token');
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
    }
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
  static void _showWebBanner(String? title, String? body) {
    if (title == null) return;
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body != null && body.isNotEmpty) Text(body),
            ],
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // Tampilkan local notification saat app di foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;

    if (kIsWeb) {
      final title = notification?.title ?? message.data['title'] as String?;
      final body  = notification?.body  ?? message.data['body']  as String?;
      // Browser sering suppress Notification API saat tab aktif — tampilkan
      // in-app banner sebagai fallback yang selalu muncul.
      _showWebBanner(title, body);
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

  static void _handleNotificationTap(RemoteMessage message) =>
      _navigateFromData(message.data);

  static void _navigateFromData(Map<String, dynamic> data) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;
    final action = data['action'] as String?;

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
