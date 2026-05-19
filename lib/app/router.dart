
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/presentation/pages/attachment-view/index.dart';
import 'package:progress_group/features/contact/presentation/pages/contact-dropdown/index.dart';
import 'package:progress_group/features/home/presentation/pages/task/index.dart';
import 'package:progress_group/features/inbox/presentation/pages/qr/index.dart';

import '../features/attandance/data/arguments/attandance_args.dart';
import '../features/attandance/presentation/pages/attandance-page/index.dart';
import '../features/attandance/presentation/pages/camera/index.dart';
import '../features/auth/presentation/pages/forgot-password/index.dart';
import '../features/auth/presentation/pages/login/index.dart';
import '../features/auth/presentation/pages/profile/index.dart';
import '../features/contact/data/arguments/contact_detail_args.dart';
import '../features/contact/presentation/pages/contact-add/index.dart';
import '../features/contact/presentation/pages/contact-detail/index.dart';
import '../features/contact/presentation/pages/contact-form/index.dart';
import 'package:progress_group/features/contact/presentation/pages/date-selection/index.dart';
import '../features/contact/presentation/pages/contact-page/index.dart';
import '../features/home/presentation/pages/home/index.dart';
import '../features/inbox/data/arguments/inbox_detail_args.dart';
import '../features/inbox/presentation/pages/inbox-detail/index.dart';
import '../features/inbox/presentation/pages/inbox-page/index.dart';
import '../features/notif/presentation/pages/notif-page/index.dart';
import '../features/saleskit/data/arguments/saleskit_detail_args.dart';
import '../features/saleskit/presentation/saleskit-page/index.dart';
import '../features/site-plan/domain/entities/project_site.dart';
import '../features/site-plan/presentation/project-list/index.dart';
import '../features/site-plan/presentation/site-plan-page/index.dart';
import '../features/splash/presentation/pages/index.dart';
import 'main_layout.dart';

class AppRouter {
  static GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Notifier ini mengontrol status autentikasi.
  /// Saat nilainya berubah, GoRouter otomatis mengevaluasi ulang [redirect].
  static final authNotifier = ValueNotifier<bool>(false);

  static late GoRouter router;

  static void init() {
    // 🔥 Buat GlobalKey baru setiap kali init dipanggil
    rootNavigatorKey = GlobalKey<NavigatorState>();
    
    router = GoRouter(
      initialLocation: '/splash',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final isLoggedIn = authNotifier.value;
        final location = state.matchedLocation;

        if (location == '/splash') return null;
        if (location.startsWith('/forgot-password')) return null;

        if (!isLoggedIn && location != '/login') return '/login';
        if (isLoggedIn && location == '/login') return '/';

        return null;
      },
      routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
          builder: (context, state) {
          final args = state.extra as int;
          return ForgotPasswordPage(step: args);}
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
            routes: [
              GoRoute(
                name: 'taskHome',
                path: 'task-home',
                builder: (context, state) {
                  return const TaskPage();
                },
              ),
            ]
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactPage(),
            routes: [
              GoRoute(
                name: 'detailContact',
                path: 'detail-contact',
                builder: (context, state) {
                  final args = state.extra as ContactDetailArgs;
                  return ContactDetailPage(args: args);
                },
              ),
              GoRoute(
                name: 'formContact',
                path: 'form-contact',
                builder: (context, state) {
                  final args = state.extra as ContactDetailArgs;
                  return ContactFormPage(args: args);
                },
              ),
              GoRoute(
                name: 'detailContactDropdown',
                path: 'detail-contact-dropdown',
                builder: (context, state) {
                  final args = state.extra as ContactDropdownArgs;
                  return DropdownListContact(args: args);
                },
              ),
              GoRoute(
                name: 'addContact',
                path: 'add-contact',
                builder: (context, state) {
                  final args = state.extra as ContactDetailArgs;
                  return ContactAddPage(args: args);
                },
              ),
              GoRoute(
                name: 'attachmentWebView',
                path: 'attachment-web-view',
                builder: (context, state) {
                  final args = state.extra as String;
                  return AttachmentWebViewPage(url: args);
                },
              ),
              GoRoute(
                name: 'dateFilter',
                path: 'date-filter',
                builder: (context, state) {
                  final extra = state.extra as Map<String, String?>?;
                  return DateFilterPage(
                    selectedLabel: extra?['label'],
                    startDate: extra?['startDate'],
                    endDate: extra?['endDate'],
                  );
                },
              ),
             
            ],
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxPage(),
            routes: [
              GoRoute(
                name: 'detailInbox',
                path: 'detail-inbox',
                builder: (context, state) {
                  final args = state.extra as InboxDetailArgs;
                  return InboxDetailPage(args: args);
                },
              ),
              GoRoute(
                name: 'qrScanner',
                path: 'qrScanner',
                builder: (context, state) {
                  final args = state.extra as String;
                  return QrScannerPage(sessionId: args);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/site-plan',
            builder: (context, state) => const SitePlanPage(),
            routes: [
              GoRoute(
                name: 'projectList',
                path: 'project-list',
                builder: (context, state) {
                  final args = (state.extra as List<ProjectSite>?) ?? [];
                  return ProjectListPage(sites: args);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/sales-kit',
            name: "salesKit",
            builder: (context, state) {
              final args = (state.extra as SalesKitDetailArgs?) ?? SalesKitDetailArgs();
              return SalesKitPage(args: args);
            },
          ),
          GoRoute(
            path: '/attandance',
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['initialTab'];
              final initialTab = tabParam != null ? int.tryParse(tabParam) : null;
              return AttandancePage(initialTab: initialTab);
            },
            routes: [
              GoRoute(
                path: 'camera', // ✅ TANPA "/"
                name: 'camera',
                builder: (context, state) {
                  final args = state.extra as AttandanceArgs;
                  return CameraPage(args: args);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notif',
            name: "notif",
            builder: (context, state) => const NotifPage(),
          ),

          GoRoute(
            path: '/profile',
            name: "profile",
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}
}