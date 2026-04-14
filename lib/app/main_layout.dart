import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';

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

  int get _currentIndex {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/contact')) return 1;
    if (location.startsWith('/inbox')) return 2;
    if (location.startsWith('/site-plan')) return 4;
    if (location.startsWith('/sales-kit')) return 5;
    if (location.startsWith('/attandance')) return 6;
    if (location.startsWith('/profile')) return 7;
    return -1;
  }
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String newUri = GoRouterState.of(context).uri.toString();
    if (_currentUri != newUri) {
      _currentUri = newUri;
      _lastPressedAt = null; // Reset double tap timer on page change
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Remove message on navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final location = GoRouterState.of(context).uri.path;
    final isAttendance = location.startsWith('/attandance');

    final statusBarStyle = isAttendance
        ? const SystemUiOverlayStyle(statusBarColor: Color(primaryColor),statusBarIconBrightness: Brightness.light,statusBarBrightness: Brightness.dark)
        : const SystemUiOverlayStyle(statusBarColor: Colors.white,statusBarIconBrightness: Brightness.dark,statusBarBrightness: Brightness.light,);
    
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
        final isTimeout = _lastPressedAt == null ||
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
      bottomNavigationBar: Container(
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, path: '/', icon: icNavHome, label: 'Home', isActive: currentIndex != 1 && currentIndex != 2 && currentIndex != 4),
            _buildNavItem(context, path: '/contact', icon: icSidebarContacts, label: 'Contact', isActive: currentIndex == 1),
            _buildNavItem(context, path: '/inbox', icon: icSidebarInbox, label: 'Inbox', isActive: currentIndex == 2),
            _buildNavItem(context, path: '/site-plan', icon: icSidebarSitePlan, label: 'Site Plan', isActive: currentIndex == 4),
          ],
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: Color(primaryColor),
                            child: Icon(Icons.person, color: Colors.white, size: 37),
                          ),
                          SizedBox(width: 10),
                          Column(
                            children: [
                              Text('Progress Group',style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(grey2Color))),
                              Text('joe@progressgroup.co.id',style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(grey2Color))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildDrawerItem(context, icSidebarDashboard, 'Dashboard', path: '/', index: 0),
              _buildDrawerItem(context, icSidebarContacts, 'Contacts', path: '/contact', index: 1),
              _buildDrawerItem(context, icSidebarInbox, 'Inbox', path: '/inbox', index: 2),
              _buildDrawerItem(context, icSidebarSitePlan, 'Site Plan', path: '/site-plan', index: 4),
              _buildDrawerItem(context, icSidebarSalesKit, 'Sales Kit', path: '/sales-kit', index: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
               _buildDrawerItem(context, icSidebarAttandance, 'Attandance', path: '/attandance', index: 6),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // WA Redirect
                  },
                  icon: Image.asset(icSidebarChatSA, width: 24, height: 24, color: Colors.white),
                  label: const Text('Chat SA',style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(primaryColor),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric( horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.go('/login'),
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

  Widget _buildDrawerItem(BuildContext context, String icon, String title, {required String path, required int index}) {
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
                    Image.asset(
                      icon,
                      width: 24,
                      height: 24,
                      color: isActive ? Color(primaryColor) : Color(grey2Color),
                    ),
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

  Widget _buildNavItem(BuildContext context, {required String path, required String icon, required String label, required bool isActive}) {

    return GestureDetector(
      onTap: () => context.go(path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.linearToEaseOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Color(grey6Color) : Colors.transparent,
            borderRadius: BorderRadius.circular(20)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Image.asset(
                 icon,
                 width: 24,
                 height: 24,
                 color: isActive ? Color(primaryColor) : Color(grey2Color),
               ),
              if (isActive) ...[
                const SizedBox(width: 10),
                Text(label,style: TextStyle(color: Color(primaryColor),fontWeight: FontWeight.w500,fontSize: 12,)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
