import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/pwa_install.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_event.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/utils/widget/impersonation_banner.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/old_app_banner.dart';
import 'package:progress_group/core/utils/widget/environment_banner.dart';
import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';
import 'package:progress_group/features/app-menu/presentation/app_menu_mapping.dart';
import 'package:progress_group/features/app-menu/presentation/state/app_menu/app_menu_cubit.dart';
import 'package:progress_group/features/app-menu/presentation/state/app_menu/app_menu_state.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  DateTime? _lastPressedAt;
  String? _currentUri;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _pwaAvailable = false;
  bool _isIosSafariDevice = false;
  String _appVersion = '';

  StreamSubscription<AuthState>? _permissionsSub;

  /// True sampai menu server selesai diambil dan tujuan Home diputuskan (hanya saat di '/').
  bool _landing = true;

  /// Home cadangan saat server tidak memberi menu.
  static const String _defaultHomePath = '/report';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('main_layout');
    context.read<WhatsappActivityBloc>().add(
      const FetchWhatsappUnreadSummaryEvent(0),
    );
    _setupPwa();
    _loadAppVersion();
    // Menu sidebar dari server: diambil sekarang, dan setiap izin dimuat ulang (PermissionsLoaded).
    _landOnHome();
    _permissionsSub = context.read<AuthBloc>().stream.listen((state) {
      if (state is PermissionsLoaded) context.read<AppMenuCubit>().load();
    });
  }

  @override
  void dispose() {
    _permissionsSub?.cancel();
    super.dispose();
  }

  /// Setelah login (atau buka app dengan sesi tersimpan), tujuan pertama adalah modul Home dari
  /// server. Hanya dijalankan saat shell terbuka di '/', supaya deep link (mis. /contact) tidak
  /// tertimpa. Kalau server belum memberi menu, user tetap di '/'.
  Future<void> _landOnHome() async {
    final cubit = context.read<AppMenuCubit>();
    try {
      await cubit.load().timeout(const Duration(seconds: 15));
    } catch (_) {
      // Timeout / gagal: lanjut dengan menu yang ada (atau kosong).
    }
    if (!mounted) return;
    final atRoot = GoRouterState.of(context).uri.path == '/';
    final menu = cubit.state.menu;
    // Tanpa menu dari server (gagal sejak awal): Report jadi Home default.
    final path = menu == null
        ? _defaultHomePath
        : (menu.homeModule == null ? null : appMenuPathFor(menu.homeModule!.code));
    // Pindah dulu, baru loader dilepas, supaya feed tidak sempat kelihatan.
    if (atRoot && path != null && path != '/') context.go(path);
    setState(() => _landing = false);
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  static const _navEventByPath = {
    '/': 'main_layout_nav_home',
    '/contact': 'main_layout_nav_contact',
    '/attandance': 'main_layout_nav_attendance',
    '/inbox': 'main_layout_nav_inbox',
    '/site-plan': 'main_layout_nav_site_plan',
  };

  static const _drawerNavEventByPath = {
    '/': 'main_layout_drawer_nav_home',
    '/report': 'main_layout_drawer_nav_dashboard',
    '/contact': 'main_layout_drawer_nav_contacts',
    '/inbox': 'main_layout_drawer_nav_inbox',
    '/site-plan': 'main_layout_drawer_nav_site_plan',
    '/sales-kit': 'main_layout_drawer_nav_sales_kit',
    '/siap-huni': 'main_layout_drawer_nav_siap_huni',
    '/attandance': 'main_layout_drawer_nav_attendance',
    '/reserve-order': 'main_layout_drawer_nav_reserve_order',
    '/landing-page': 'main_layout_drawer_nav_info',
  };

  void _setupPwa() {
    if (isPwaRunningStandalone()) return;

    if (isIosSafari()) {
      setState(() => _isIosSafariDevice = true);
      return;
    }

    registerPwaCallbacks(
      onAvailable: () {
        if (mounted) setState(() => _pwaAvailable = true);
      },
      onInstalled: () {
        if (mounted) setState(() => _pwaAvailable = false);
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && isPwaInstallAvailable()) {
        setState(() => _pwaAvailable = true);
      }
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Color(redAccentColor)),
            ),
          ),
        ],
      ),
    );
  }

  void _showIosInstallInstructions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(greyShade300),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Install Aplikasi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan ke Home Screen untuk pengalaman terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(greyShade600)),
            ),
            const SizedBox(height: 24),
            _iosStep(
              icon: Icons.ios_share,
              text:
                  'Tap ikon Share (kotak dengan panah ke atas) di toolbar Safari',
            ),
            const SizedBox(height: 16),
            _iosStep(
              icon: Icons.add_box_outlined,
              text: 'Scroll ke bawah dan pilih "Add to Home Screen"',
            ),
            const SizedBox(height: 16),
            _iosStep(
              icon: Icons.check_circle_outline,
              text: 'Tap "Add" di pojok kanan atas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _iosStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: Color(primaryColor)),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  int get _currentIndex {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/' || location.startsWith('/marketing-feed')) return 0;
    if (location.startsWith('/contact')) return 1;
    if (location.startsWith('/inbox')) return 2;
    if (location.startsWith('/site-plan')) return 4;
    if (location.startsWith('/sales-kit')) return 5;
    if (location.startsWith('/attandance')) return 6;
    if (location.startsWith('/profile')) return 7;
    if (location.startsWith('/landing-page')) return 8;
    if (location.startsWith('/reserve-order')) return 10;
    if (location.startsWith('/report')) return 11;
    return -1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String newUri = GoRouterState.of(context).uri.toString();
    if (_currentUri != newUri) {
      final oldUri = _currentUri ?? '';
      _currentUri = newUri;
      _lastPressedAt = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      context.read<AuthBloc>().add(FetchPermissionsEvent());

      final wasInSection =
          oldUri.startsWith('/contact') || oldUri.startsWith('/inbox');
      final isNowInSection =
          newUri.startsWith('/contact') || newUri.startsWith('/inbox');
      if (wasInSection && !isNowInSection) {
        context.read<ContactBloc>().add(const ResetContactFiltersEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final location = GoRouterState.of(context).uri.path;
    final isAttendance = location.startsWith('/attandance');
    // Home (Marketing Feed) & Report (dashboard lama) sama-sama punya tombol menu di header.
    final hasDrawer = location == '/' || location == '/report';

    final statusBarStyle = isAttendance
        ? const SystemUiOverlayStyle(
            statusBarColor: Color(primaryColor),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Color(whiteColor),
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
            return;
          }

          if (context.canPop()) {
            context.pop();
            return;
          }

          if (location != '/' && location != '/login') {
            context.go('/');
            return;
          }

          final now = DateTime.now();
          final isTimeout =
              _lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2);

          if (isTimeout) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tekan sekali lagi untuk keluar'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            AnalyticsService.logEvent('main_layout_exit_app_confirm');
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawerEnableOpenDragGesture: false,
          drawer: hasDrawer ? _buildFloatingDrawer(context) : null,
          drawerScrimColor: Color(background2Color).withOpacity(0.16),
          body: Column(
            children: [
              const EnvironmentBanner(),
              const ImpersonationBanner(),
              const OldAppBanner(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    return Stack(
                      children: [
                        _landing && location == '/'
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Color(primaryColor),
                                ),
                              )
                            : widget.child,
                        if (hasDrawer)
                          Positioned(
                            left: 20,
                            top: 10,
                            bottom: 0,
                            width: 40,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                if (details.delta.dx > 12) {
                                  AnalyticsService.logEvent(
                                    'main_layout_open_drawer',
                                  );
                                  Scaffold.of(context).openDrawer();
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: location.endsWith('/camera')
              ? null
              // Inset bawah dihitung di DALAM Container supaya background putih ikut mengisi
              // area home indicator iOS — lihat _navBottomPadding.
              : Container(
                  decoration: BoxDecoration(
                    color: Color(whiteColor),
                    boxShadow: [
                      BoxShadow(
                        color: Color(blackColor).withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      6,
                      15,
                      6,
                      _navBottomPadding(context),
                    ),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (prev, curr) =>
                          curr is PermissionsLoading ||
                          curr is PermissionsLoaded ||
                          curr is PermissionsError,
                      builder: (context, state) {
                        if (state is PermissionsLoading) {
                          return const ShimmerBottomNav();
                        }

                        if (state is PermissionsError) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 18,
                                color: Color(greyShade400),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gagal memuat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(greyShade400),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  AnalyticsService.logEvent(
                                    'main_layout_retry_permissions',
                                  );
                                  context.read<AuthBloc>().add(
                                    FetchPermissionsEvent(),
                                  );
                                },
                                child: Text(
                                  'Coba lagi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(primaryColor),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHomeNavItem(context, currentIndex),
                            if (PermissionsHelper.canAccessContacts)
                              _buildNavItem(
                                context,
                                path: '/contact',
                                icon: icSidebarContacts,
                                label: 'Contact',
                                isActive: currentIndex == 1,
                              ),
                            if (PermissionsHelper.canAccessAttendance)
                              _buildNavItem(
                                context,
                                path: '/attandance',
                                icon: icNavAttendance,
                                label: 'Attendance',
                                isActive: currentIndex == 6,
                              ),
                            if (PermissionsHelper.canAccessInbox)
                              BlocBuilder<
                                WhatsappActivityBloc,
                                WhatsappActivityState
                              >(
                                builder: (context, state) {
                                  final totalUnread = state.data.fold<int>(
                                    0,
                                    (sum, item) => sum + item.unreadCount,
                                  );
                                  return _buildNavItem(
                                    context,
                                    path: '/inbox',
                                    icon: icSidebarInbox,
                                    label: 'Inbox',
                                    isActive: currentIndex == 2,
                                    badgeCount: totalUnread,
                                  );
                                },
                              ),
                            if (PermissionsHelper.canAccessSitePlan)
                              _buildNavItem(
                                context,
                                path: '/site-plan',
                                icon: icSidebarSitePlan,
                                label: 'Site Plan',
                                isActive: currentIndex == 4,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Jarak bawah navbar. Android/web: padding 15 + inset sistem (biasanya 0).
  // iOS: area home indicator (~34pt) cukup dipakai separuh tanpa tambahan 15 —
  // kalau dipakai penuh + 15, ikon kelihatan jauh lebih tinggi dibanding Android.
  double _navBottomPadding(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final isIOSApp = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOSApp && inset > 0) return inset / 2 > 15 ? inset / 2 : 15;
    return 15 + inset;
  }

  Widget _buildFloatingDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.6;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Color(whiteColor),
        elevation: 7,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          AnalyticsService.logEvent(
                            'main_layout_drawer_open_profile',
                          );
                          context.push('/profile');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              BlocBuilder<ProfileBloc, ProfileState>(
                                builder: (context, state) {
                                  String userName = "User";
                                  String userPosition = "";
                                  String? photoUrl;
                                  if (state is ProfileLoaded) {
                                    final profile = state.profile;
                                    userName = profile.fullName;
                                    final isSales =
                                        profile.userRoleId == 3 ||
                                        profile.salesPersonId != null;
                                    userPosition = isSales
                                        ? (profile.positionName ?? "")
                                        : (profile.userRoleName ?? "");
                                    photoUrl = profile.photoUrl;
                                  }
                                  return Row(
                                    children: [
                                      ClipOval(
                                        child: photoUrl != null
                                            ? Image.network(
                                                photoUrl,
                                                width: 54,
                                                height: 54,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    CircleAvatar(
                                                      radius: 27,
                                                      backgroundColor: Color(
                                                        primaryColor,
                                                      ),
                                                      child: Icon(
                                                        Icons.person,
                                                        color: Color(
                                                          whiteColor,
                                                        ),
                                                        size: 37,
                                                      ),
                                                    ),
                                              )
                                            : CircleAvatar(
                                                radius: 27,
                                                backgroundColor: Color(
                                                  primaryColor,
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  color: Color(whiteColor),
                                                  size: 37,
                                                ),
                                              ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: Color(grey2Color),
                                              ),
                                            ),
                                            if (userPosition.isNotEmpty)
                                              Text(
                                                userPosition,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(grey2Color),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Slot Home: selalu berlabel "Home", membuka modul is_home dari server.
                      BlocBuilder<AppMenuCubit, AppMenuState>(
                        builder: (context, menuState) {
                          final menu = menuState.menu;
                          // Tanpa menu dari server: Home = Report (cadangan).
                          if (menu == null) {
                            return _buildDrawerItem(
                              context,
                              icNavHome,
                              'Home',
                              path: _defaultHomePath,
                              index: appMenuIndexFor('REPORT'),
                            );
                          }
                          final homeModule = menu.homeModule;
                          final homePath = homeModule == null
                              ? null
                              : appMenuPathFor(homeModule.code);
                          return _buildDrawerItem(
                            context,
                            icNavHome,
                            'Home',
                            path: homePath ?? '/',
                            index: homeModule == null
                                ? appMenuHomeIndex
                                : appMenuIndexFor(homeModule.code),
                          );
                        },
                      ),
                      // Daftar modul dari server (urutan sudah benar dari server), tanpa modul Home.
                      BlocBuilder<AppMenuCubit, AppMenuState>(
                        builder: (context, menuState) {
                          final items = (menuState.menu?.modules ?? const [])
                              .where((m) => !m.isHome)
                              .toList();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final module in items) ...[
                                // Garis pemisah sebelum Attendance (sama seperti sebelumnya).
                                if (module.code == 'ATTENDANCE')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Divider(),
                                  ),
                                _buildAppMenuItem(context, module),
                              ],
                            ],
                          );
                        },
                      ),
                      const Spacer(),

                      const Spacer(),
                      _buildDrawerItem(
                        context,
                        '',
                        'Info & Panduan',
                        path: '/landing-page',
                        index: 8,
                        iconData: Icons.info,
                      ),
                      if (_pwaAvailable || _isIosSafariDevice)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () {
                              AnalyticsService.logEvent(
                                'main_layout_install_app',
                              );
                              Navigator.of(context).pop();
                              if (_isIosSafariDevice) {
                                _showIosInstallInstructions();
                              } else {
                                showPwaInstallPrompt().then((_) {
                                  if (mounted)
                                    setState(
                                      () => _pwaAvailable =
                                          isPwaInstallAvailable(),
                                    );
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.install_mobile_outlined,
                                  color: Color(primaryColor),
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Install App",
                                  style: TextStyle(
                                    color: Color(primaryColor),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_pwaAvailable || _isIosSafariDevice)
                        const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            AnalyticsService.logEvent('main_layout_logout');
                            Navigator.of(context).pop();
                            _showLogoutConfirmation();
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.login_outlined,
                                color: Color(grey2Color),
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Color(grey2Color),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_appVersion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Text(
                              'v$_appVersion',
                              style: TextStyle(
                                color: Color(grey4Color),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Item sidebar dari menu server. Kode yang belum dipetakan tampil tanpa aksi.
  Widget _buildAppMenuItem(BuildContext context, AppMenuItemEntity module) {
    final spec = appMenuIconFor(module.icon);
    return _buildDrawerItem(
      context,
      spec.asset ?? '',
      module.label,
      path: appMenuPathFor(module.code),
      index: appMenuIndexFor(module.code),
      iconData: spec.iconData,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String icon,
    String title, {
    required String? path,
    required int index,
    IconData? iconData,
    String? badge,
  }) {
    final currentIndex = _currentIndex;
    final isActive = currentIndex == index || (index == 4 && currentIndex == 3);

    return InkWell(
      onTap: () {
        if (path == null) return;
        final event = _drawerNavEventByPath[path];
        if (event != null) AnalyticsService.logEvent(event);
        context.go(path);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(left: 12, right: 0, top: 4, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Color(primaryColor).withOpacity(0.08)
                      : Color(transparentColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    iconData != null
                        ? Icon(
                            iconData,
                            size: 24,
                            color: isActive
                                ? Color(primaryColor)
                                : Color(grey2Color),
                          )
                        : Image.asset(
                            icon,
                            width: 24,
                            height: 24,
                            color: isActive
                                ? Color(primaryColor)
                                : Color(grey2Color),
                          ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isActive
                            ? Color(primaryColor)
                            : Color(grey2Color),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(orangeAccentColor),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(whiteColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? Color(primaryColor) : Color(transparentColor),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab Home di bottom nav: ikon dan label tetap. Yang dinamis hanya tujuan ketuknya, yaitu
  /// modul `is_home` dari server. Tanpa menu dari server, tab membuka Report (cadangan).
  Widget _buildHomeNavItem(BuildContext context, int currentIndex) {
    return BlocBuilder<AppMenuCubit, AppMenuState>(
      builder: (context, menuState) {
        final menu = menuState.menu;
        if (menu == null) {
          return _buildNavItem(
            context,
            path: _defaultHomePath,
            icon: icNavHome,
            label: 'Home',
            isActive: currentIndex == appMenuIndexFor('REPORT'),
          );
        }
        final home = menu.homeModule;
        final path = home == null ? '/' : (appMenuPathFor(home.code) ?? '/');
        final targetIndex = home == null
            ? appMenuHomeIndex
            : appMenuIndexFor(home.code);
        return _buildNavItem(
          context,
          path: path,
          icon: icNavHome,
          label: 'Home',
          isActive: currentIndex == targetIndex,
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String path,
    required String icon,
    required String label,
    required bool isActive,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        final event = _navEventByPath[path];
        if (event != null) AnalyticsService.logEvent(event);
        context.go(path);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    icon,
                    width: 30,
                    height: 30,
                    color: isActive ? Color(primaryColor) : Color(grey2Color),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 8,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(redAccentColor),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Color(whiteColor),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
