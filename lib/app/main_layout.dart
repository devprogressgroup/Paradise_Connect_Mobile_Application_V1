import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<WhatsappActivityBloc>().add(const FetchWhatsappUnreadSummaryEvent(0));
    _setupPwa();
  }

  void _setupPwa() {
    // Already running as installed PWA — no need to show install prompt
    if (isPwaRunningStandalone()) return;

    // iOS Safari doesn't fire beforeinstallprompt — show manual instruction banner
    if (isIosSafari()) {
      setState(() => _isIosSafariDevice = true);
      return;
    }

    // Register callbacks: browser will call these the moment beforeinstallprompt fires,
    // even if it fires after Flutter is fully loaded (common on slow connections)
    registerPwaCallbacks(
      onAvailable: () {
        if (mounted) setState(() => _pwaAvailable = true);
      },
      onInstalled: () {
        if (mounted) setState(() => _pwaAvailable = false);
      },
    );

    // Also check immediately in case the event already fired before we registered
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && isPwaInstallAvailable()) {
        setState(() => _pwaAvailable = true);
      }
    });
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
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
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _iosStep(
              icon: Icons.ios_share,
              text: 'Tap ikon Share (kotak dengan panah ke atas) di toolbar Safari',
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
    if (location == '/') return 0;
    if (location.startsWith('/contact')) return 1;
    if (location.startsWith('/inbox')) return 2;
    if (location.startsWith('/site-plan')) return 4;
    if (location.startsWith('/sales-kit')) return 5;
    if (location.startsWith('/attandance')) return 6;
    if (location.startsWith('/profile')) return 7;
    if (location.startsWith('/landing-page')) return 8;
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

      final wasInSection = oldUri.startsWith('/contact') || oldUri.startsWith('/inbox');
      final isNowInSection = newUri.startsWith('/contact') || newUri.startsWith('/inbox');
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

    final statusBarStyle = isAttendance  ? const SystemUiOverlayStyle(statusBarColor: Color(primaryColor),statusBarIconBrightness: Brightness.light,statusBarBrightness: Brightness.dark)  : const SystemUiOverlayStyle(statusBarColor: Colors.white,statusBarIconBrightness: Brightness.dark,statusBarBrightness: Brightness.light,);
    
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
        final isTimeout = _lastPressedAt == null ||now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (isTimeout) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
    child: Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: location == '/' ? _buildFloatingDrawer(context) : null,
      drawerScrimColor: Color(background2Color).withOpacity(0.16),
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              widget.child,
              if (location == '/')
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      if (details.delta.dx > 12) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: location.endsWith('/camera')
          ? null
          : Container(
        decoration: BoxDecoration(
          color: Color(whiteColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) => curr is PermissionsLoading || curr is PermissionsLoaded || curr is PermissionsError,
          builder: (context, state) {
            if (state is PermissionsLoading) {
              return const ShimmerBottomNav();
            }

            if (state is PermissionsError) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('Gagal memuat', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.read<AuthBloc>().add(FetchPermissionsEvent()),
                    child: Text('Coba lagi', style: TextStyle(fontSize: 12, color: Color(primaryColor), fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, path: '/', icon: icNavHome, label: 'Home', isActive: currentIndex == 0),
                if (PermissionsHelper.canAccessContacts)
                  _buildNavItem(context, path: '/contact', icon: icSidebarContacts, label: 'Contact', isActive: currentIndex == 1),
                if (PermissionsHelper.canAccessAttendance)
                  _buildNavItem(context, path: '/attandance', icon: icNavActivity, label: 'Attendance', isActive: currentIndex == 6),
                if (PermissionsHelper.canAccessInbox)
                  BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
                    builder: (context, state) {
                      final totalUnread = state.data.fold<int>(0, (sum, item) => sum + item.unreadCount);
                      return _buildNavItem(context, path: '/inbox', icon: icSidebarInbox, label: 'Inbox', isActive: currentIndex == 2, badgeCount: totalUnread);
                    },
                  ),
                if (PermissionsHelper.canAccessSitePlan)
                  _buildNavItem(context, path: '/site-plan', icon: icSidebarSitePlan, label: 'Site Plan', isActive: currentIndex == 4),
              ],
            );
          },
        ),
      ),
    )));
  }


  Widget _buildFloatingDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.6; 

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 7,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  context.push('/profile');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric( horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          String userName = "User";
                          String userPosition = "";
                          String? photoUrl;
                          if (state is ProfileLoaded) {
                            userName = state.profile.fullName;
                            userPosition = state.profile.positionName ?? "";
                            photoUrl = state.profile.photoUrl;
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
                                        errorBuilder: (_, __, ___) => CircleAvatar(
                                          radius: 27,
                                          backgroundColor: Color(primaryColor),
                                          child: Icon(Icons.person, color: Colors.white, size: 37),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 27,
                                        backgroundColor: Color(primaryColor),
                                        child: Icon(Icons.person, color: Colors.white, size: 37),
                                      ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(grey2Color))),
                                    if (userPosition.isNotEmpty)
                                      Text(userPosition, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(grey2Color))),
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
              _buildDrawerItem(context, icSidebarDashboard, 'Dashboard', path: '/', index: 0),
              if (PermissionsHelper.canAccessContacts)
                _buildDrawerItem(context, icSidebarContacts, 'Contacts', path: '/contact', index: 1),
              if (PermissionsHelper.canAccessInbox)
                _buildDrawerItem(context, icSidebarInbox, 'Inbox', path: '/inbox', index: 2),
              if (PermissionsHelper.canAccessSitePlan)
                _buildDrawerItem(context, icSidebarSitePlan, 'Site Plan', path: '/site-plan', index: 4),
              if (PermissionsHelper.canAccessSalesKit)
                _buildDrawerItem(context, icSidebarSalesKit, 'Sales Kit', path: '/sales-kit', index: 5),
              _buildDrawerItem(context, '', 'Info & Panduan', path: '/landing-page', index: 8, iconData: Icons.language_outlined),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              if (PermissionsHelper.canAccessAttendance)
                _buildDrawerItem(context, icSidebarAttandance, 'Attandance', path: '/attandance', index: 6),
              const Spacer(),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 40.0),
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       // WA Redirect
              //     },
              //     icon: Image.asset(icSidebarChatSA, width: 24, height: 24, color: Colors.white),
              //     label: const Text('Chat SA',style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Color(primaryColor),
              //       minimumSize: const Size(double.infinity, 48),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //     ),
              //   ),
              // ),
              const Spacer(),
              if (_pwaAvailable || _isIosSafariDevice)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      if (_isIosSafariDevice) {
                        _showIosInstallInstructions();
                      } else {
                        showPwaInstallPrompt().then((_) {
                          if (mounted) setState(() => _pwaAvailable = isPwaInstallAvailable());
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.install_mobile_outlined, color: Color(primaryColor), size: 24),
                        SizedBox(width: 10),
                        Text("Install App", style: TextStyle(color: Color(primaryColor), fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              if (_pwaAvailable || _isIosSafariDevice) const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric( horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<AuthBloc>().add(LogoutEvent());
                  },
                  child: Row(
                    children: [
                      Icon(Icons.login_outlined, color: Color(grey2Color), size: 24),
                      SizedBox(width: 10),
                      Text("Logout", style: TextStyle(color: Color(grey2Color), fontSize: 16, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String icon, String title, {required String path, required int index, IconData? iconData}) {
    final currentIndex = _currentIndex;
    final isActive = currentIndex == index || (index == 4 && currentIndex == 3);

    return InkWell(
      onTap: () {
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
                  color: isActive ? Color(primaryColor).withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    iconData != null
                        ? Icon(iconData, size: 24, color: isActive ? Color(primaryColor) : Color(grey2Color))
                        : Image.asset(icon, width: 24, height: 24, color: isActive ? Color(primaryColor) : Color(grey2Color)),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? Color(primaryColor) : Color(grey2Color),
                      ),
                    ),
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
                color: isActive ? Color(primaryColor) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required String path, required String icon, required String label, required bool isActive, int badgeCount = 0}) {
    return GestureDetector(
      onTap: () {
        context.go(path);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 6),
              // decoration: BoxDecoration(
              //   color: isActive ? Color(primaryColor).withOpacity(0.08) : Colors.transparent,
              //   borderRadius: BorderRadius.circular(50),
              // ),
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
                  // AnimatedSize(
                  //   duration: const Duration(milliseconds: 200),
                  //   curve: Curves.easeOut,
                  //   child: isActive
                  //       ? Padding(
                  //           padding: const EdgeInsets.only(top: 4),
                  //           child: Text(
                  //             label,
                  //             style: TextStyle(
                  //               fontSize: 11,
                  //               fontWeight: FontWeight.w600,
                  //               color: Color(primaryColor),
                  //             ),
                  //           ),
                  //         )
                  //       : const SizedBox.shrink(),
                  // ),
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
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
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
