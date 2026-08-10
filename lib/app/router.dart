
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/attandance/presentation/pages/approval/index.dart';
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
import '../features/auth/presentation/pages/impersonate/index.dart';
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
import '../features/site-plan/domain/entities/unit_detail.dart';
import '../features/site-plan/presentation/blank/siteplan-blank.dart';
import '../features/site-plan/presentation/project-list/index.dart';
import '../features/site-plan/presentation/site-plan-page/index.dart';
import '../features/landing-page/presentation/landing-page/index.dart';
import '../features/splash/presentation/pages/index.dart';
import '../features/permission-gate/presentation/pages/index.dart';
import '../features/siap-huni/presentation/pages/index.dart';
import '../features/contact/presentation/pages/pipeline/index.dart';
import 'main_layout.dart';
import '../core/network/api_constants.dart';
import '../core/services/analytics_service.dart';
import '../core/utils/helpers/permissions_helper.dart';
import '../core/utils/route_observer.dart';

/// Pola path App Links yang dianggap "hash link" — https://{APP_LINK_DOMAIN}/link/{hash}
/// (hash di-generate AppDeepLinkController, lihat docs/app-links-site-plan-blank.md §7).
/// SEBELUMNYA path-nya literal "/link/site-plan-blank" (dicocokkan lewat Map); SEKARANG segmen
/// terakhirnya hash acak per-share, jadi harus di-resolve ke server dulu (lihat _resolveAppLinkHash)
/// buat tahu ini link menuju halaman internal yang mana.
final RegExp _appLinkHashPattern = RegExp(r'^/link/([A-Za-z0-9]+)$');

/// Map "target" hasil resolve (dari AppLinkResolveController) -> path internal app. Cuma 1 entry
/// sekarang ('site-plan-blank') — tambah entry baru di sini kalau nanti ada target lain, TANPA
/// perlu ubah AndroidManifest.xml (intent-filter pathPrefix "/link" sudah menangkap semua path
/// di bawahnya apapun hash-nya).
const Map<String, String> _appLinkTargetRoutes = {
  'site-plan-blank': '/site-plan/blank',
};

/// Resolve https://.../link/{hash} -> path internal, hit endpoint publik GET /link/resolve/{hash}
/// (lihat AppLinkResolveController). SENGAJA pakai Dio polos (BUKAN DioClient/gateway terenkripsi
/// -/px-): endpoint ini publik & datanya tidak sensitif (cuma nama target dari daftar terbatas di
/// atas) — persis sama seperti kalau link ini dibuka di browser biasa tanpa app. DioClient juga
/// butuh AuthLocalDataSource via DI yang tidak tersedia di titik statis ini (AppRouter.init()).
Future<String?> _resolveAppLinkHash(String hash) async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
    final response = await dio.get('/link/resolve/$hash');
    final data = response.data;
    if (data is! Map) return null;
    final inner = data['data'];
    final target = inner is Map ? inner['target'] as String? : null;
    return target != null ? _appLinkTargetRoutes[target] : null;
  } catch (e) {
    debugPrint('[AppRouter] Gagal resolve app link hash "$hash": $e');
    return null;
  }
}

class AppRouter {
  static GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  
  
  static final authNotifier = ValueNotifier<bool>(false);

  static late GoRouter router;

  static void init() {
    
    rootNavigatorKey = GlobalKey<NavigatorState>();
    
    router = GoRouter(
      initialLocation: '/permission-gate',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authNotifier,
      observers: [appRouteObserver],
      redirect: (context, state) async {
        // App Links (mobile) & link dibuka langsung di browser (PWA): "location" yang
        // dilempar ke go_router itu URL LENGKAP di mobile (scheme+host+path, mis.
        // "https://devconnect.paradise.id/link/{hash}" — Android meneruskan Intent-nya
        // apa adanya) tapi cuma PATH-nya saja di web (browser sudah otomatis pisahkan
        // origin dari path). findMatch() go_router gagal cocokkan KEDUANYA ke tabel route
        // (isinya path relatif semua) dan lempar GoException("no routes for location: ...").
        // redirect TOP-LEVEL ini TETAP dipanggil oleh go_router walau matching awal gagal
        // (dievaluasi di atas match-list error, lihat configuration.dart:findMatch()+redirect()
        // punya package go_router) — jadi di SINI tempat yang benar buat translate ke path
        // internal app, SEBELUM di-match ulang. Cek berdasarkan uri.path SAJA (bukan host) —
        // otomatis benar utk kedua platform tanpa perlu hardcode domain di sini (domain App
        // Links sendiri diatur di AndroidManifest.xml, TIDAK BISA dibaca dari sini — lihat
        // catatan di sana).
        final hashMatch = _appLinkHashPattern.firstMatch(state.uri.path);
        if (hashMatch != null) {
          final internalPath = await _resolveAppLinkHash(hashMatch.group(1)!);
          if (internalPath == null) {
            // Hash tidak dikenal/gagal resolve (network error, link sudah tidak valid, dst) —
            // jangan biarkan GoException nyangkut di lokasi yang gagal match, redirect ke home.
            return '/';
          }
          // Payload unit (terenkripsi) NUMPANG di query string link asli, BUKAN dari endpoint
          // resolve (lihat catatan di _resolveAppLinkHash — resolve sengaja tidak bawa data
          // sensitif). Diteruskan apa adanya ke path internal supaya builder-nya (mis.
          // 'site_plan_blank') bisa decrypt sendiri dari state.uri.query.
          final query = state.uri.query;
          return query.isEmpty ? internalPath : '$internalPath?$query';
        }

        final isLoggedIn = authNotifier.value;
        final location = state.matchedLocation;

        if (location == '/permission-gate') return null;
        if (location == '/splash') return null;
        if (location.startsWith('/forgot-password')) return null;
        // Halaman publik (lihat definisi route-nya) — tidak boleh kena gate login, dibuka
        // customer/prospek lewat link share yang tidak punya akun sama sekali.
        if (location.startsWith('/site-plan/blank')) return null;

        if (!isLoggedIn && location != '/login') return '/login';
        if (isLoggedIn && location == '/login') return '/';

        return null;
      },
      routes: [
      GoRoute(
        path: '/permission-gate',
        builder: (context, state) => const PermissionGatePage(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
          builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return ForgotPasswordPage(step: extra['step'] as int, isRegister: extra['isRegister'] as bool? ?? false);
          }
          return ForgotPasswordPage(step: extra as int);}
      ),
      GoRoute(
        path: '/impersonate',
        name: 'impersonate',
        builder: (context, state) => const ImpersonatePage(),
      ),
      // Halaman publik — dibuka lewat link share ('/link/{hash}' -> di-redirect ke sini,
      // lihat _appLinkTargetRoutes) ke customer/prospek yang BELUM TENTU punya akun app ini.
      // SENGAJA di luar ShellRoute (tanpa MainLayout/bottom-nav) dan dikecualikan dari gate
      // login di redirect() atas — kalau dibiarkan di bawah '/site-plan' (yang butuh login +
      // PermissionsHelper.canAccessSitePlan), penerima link akan selalu kelempar ke /login.
      GoRoute(
        path: '/site-plan/blank',
        name: 'site_plan_blank',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // Dibuka dari App Link ('/link/{hash}') -> tidak ada extra, datanya ada di
          // query string ("=<ivBase64>:<ciphertextBase64>", diteruskan redirect di atas).
          final query = state.uri.query;
          final data = extra ??
              (query.isEmpty
                  ? null
                  : UnitDetail.decryptPayload(
                      query.startsWith('=') ? query.substring(1) : query,
                    ));
          return SitePlanBlank(data: data);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
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
            redirect: (context, state) => PermissionsHelper.canAccessContacts ? null : '/',
            builder: (context, state) {
              final extra = state.extra;
              List<int>? initialStatusIds;
              List<int>? initialSalesChannelIds;
              String? initialStartDate;
              String? initialEndDate;
              if (extra is Map<String, dynamic>) {
                initialStatusIds = (extra['statusIds'] as List?)?.cast<int>();
                initialSalesChannelIds = (extra['salesChannelIds'] as List?)?.cast<int>();
                initialStartDate = extra['startDate'] as String?;
                initialEndDate = extra['endDate'] as String?;
              } else if (extra is List<int>) {
                initialStatusIds = extra;
              }
              return ContactPage(
                initialStatusIds: initialStatusIds,
                initialSalesChannelIds: initialSalesChannelIds,
                initialStartDate: initialStartDate,
                initialEndDate: initialEndDate,
              );
            },
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
                  final extra = state.extra as Map<String, dynamic>?;
                  return DateFilterPage(
                    selectedLabel: extra?['label'] as String?,
                    startDate: extra?['startDate'] as String?,
                    endDate: extra?['endDate'] as String?,
                    isSingleSelect: extra?['isSingleSelect'] as bool? ?? false,
                  );
                },
              ),
             
            ],
          ),
          GoRoute(
            path: '/inbox',
            redirect: (context, state) =>
                PermissionsHelper.canAccessInbox ? null : '/',
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
            name: 'site_plan',
            redirect: (context, state) =>
                PermissionsHelper.canAccessSitePlan ? null : '/',
            builder: (context, state) => const SitePlanPage(),
            routes: [
              GoRoute(
                name: 'project_list',
                path: 'project-list',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final sites = (extra?['sites'] as List<ProjectSite>?) ?? [];
                  final selected = extra?['selected'] as ProjectSite?;
                  return ProjectListPage(sites: sites, selectedSite: selected);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/sales-kit',
            name: "sales_kit",
            redirect: (context, state) =>
                PermissionsHelper.canAccessSalesKit ? null : '/',
            builder: (context, state) {
              final args = (state.extra as SalesKitDetailArgs?) ?? SalesKitDetailArgs();
              return SalesKitPage(args: args);
            },
          ),
          GoRoute(
            path: '/attandance',
            name: 'attendance',
            redirect: (context, state) {
              if (!PermissionsHelper.canAccessAttendance) {
                debugPrint('[Router] /attandance redirect → "/" (canAccessAttendance=false)');
              }
              return PermissionsHelper.canAccessAttendance ? null : '/';
            },
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['initialTab'];
              final initialTab = tabParam != null ? int.tryParse(tabParam) : null;
              return AttandancePage(initialTab: initialTab);
            },
            routes: [
              GoRoute(
                path: 'camera', 
                name: 'camera',
                builder: (context, state) {
                  final args = state.extra as AttandanceArgs;
                  return CameraPage(args: args);
                },
              ),
              GoRoute(
                path: 'approval',
                name: 'approval',
                builder: (context, state) => const ApprovalPage(),
              ),
              GoRoute(
                name: 'attendanceOwnerDropdown',
                path: 'owner-dropdown',
                builder: (context, state) {
                  final args = state.extra as ContactDropdownArgs;
                  return DropdownListContact(args: args);
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
          GoRoute(
            path: '/landing-page',
            name: 'landing_page',
            builder: (context, state) => const LandingPage(),
          ),
          GoRoute(
            path: '/siap-huni',
            name: 'siap_huni',
            redirect: (context, state) =>
                PermissionsHelper.canAccessSiapHuni ? null : '/',
            builder: (context, state) => const SiapHuniPage(),
          ),
          GoRoute(
            path: '/pipeline',
            name: 'pipeline',
            redirect: (context, state) =>
                PermissionsHelper.canAccessContacts ? null : '/',
            builder: (context, state) {
              final extra = state.extra;
              List<int>? ids;
              String? title;
              if (extra is Map) {
                final raw = extra['statusIds'];
                if (raw is List) {
                  ids = raw.map((e) => e is int ? e : int.tryParse('$e') ?? 0).where((e) => e != 0).toList();
                }
                title = extra['title']?.toString();
              }
              return PipelineScreen(statusIds: ids, title: title);
            },
          ),
        ],
      ),
    ],
  );

    // Track setiap perpindahan route ke Firebase Analytics
    String lastScreen = '';
    router.routerDelegate.addListener(() {
      final config = router.routerDelegate.currentConfiguration;
      final matches = config.matches;
      if (matches.isEmpty) return;
      final lastRoute = matches.last.route;
      final screen = (lastRoute is GoRoute && lastRoute.name != null) ? lastRoute.name! : config.uri.path;
      if (screen.isNotEmpty && screen != lastScreen) {
        lastScreen = screen;
        AnalyticsService.logScreenView(screen);
      }
    });
  }
}