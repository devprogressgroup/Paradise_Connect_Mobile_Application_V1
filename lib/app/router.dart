

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/presentation/pages/contact-dropdown/index.dart';

import '../features/attandance/data/arguments/attandance_args.dart';
import '../features/attandance/presentation/pages/attandance-page/index.dart';
import '../features/attandance/presentation/pages/camera/index.dart';
import '../features/auth/presentation/pages/forgot-password/index.dart';
import '../features/auth/presentation/pages/login/index.dart';
import '../features/contact/data/arguments/contact_detail_args.dart';
import '../features/contact/presentation/pages/contact-add/index.dart';
import '../features/contact/presentation/pages/contact-detail/index.dart';
import '../features/contact/presentation/pages/contact-form/index.dart';
import '../features/contact/presentation/pages/contact-page/index.dart';
import '../features/home/presentation/pages/index.dart';
import '../features/inbox/data/arguments/inbox_detail_args.dart';
import '../features/inbox/presentation/pages/inbox-detail/index.dart';
import '../features/inbox/presentation/pages/inbox-page/index.dart';
import '../features/notif/presentation/pages/notif-page/index.dart';
import '../features/saleskit/data/arguments/saleskit_detail_args.dart';
import '../features/saleskit/presentation/inventory-page/index.dart';
import '../features/site-plan/domain/entities/project_site.dart';
import '../features/site-plan/presentation/project-list/index.dart';
import '../features/site-plan/presentation/site-plan-page/index.dart';
import '../features/splash/presentation/pages/index.dart';
import 'main_layout.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
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
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
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
            builder: (context, state) => const AttandancePage(),
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
        ],
      ),
    ],
  );
}
