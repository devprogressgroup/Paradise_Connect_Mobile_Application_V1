import 'dart:async';
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/ota_update_service.dart';
import 'package:progress_group/core/services/analytics_service.dart';

enum _Phase { preparing, needsPermission, downloading, installing, error }

class UpdateScreen extends StatefulWidget {
  final String downloadUrl;
  final String currentVersion;
  final String latestVersion;

  const UpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.currentVersion,
    required this.latestVersion,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _Phase _phase = _Phase.preparing;
  double _progress = 0;
  String _errorMsg = '';
  bool _awaitingPermissionResult = false;

  Timer? _dotsTimer;
  int _dots = 0;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('update_screen');
    WidgetsBinding.instance.addObserver(this);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4, end: 14).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startDownload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPermissionResult) {
      _awaitingPermissionResult = false;
      _startDownload();
    }
  }

  Future<void> _openPermissionSettings() async {
    AnalyticsService.logEvent('update_screen_open_install_permission_settings');
    _awaitingPermissionResult = true;
    await OtaUpdateService.openInstallPermissionSettings();
  }

  Future<void> _startDownload() async {
    final canInstall = await OtaUpdateService.canInstallPackages();
    if (!canInstall) {
      _dotsTimer?.cancel();
      if (mounted) setState(() => _phase = _Phase.needsPermission);
      return;
    }

    if (!mounted) return;
    if (_phase == _Phase.needsPermission) {
      _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (mounted) setState(() => _dots = (_dots + 1) % 4);
      });
    }
    setState(() => _phase = _Phase.preparing);

    OtaUpdateService.downloadAndInstall(
      downloadUrl: widget.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() {
          _phase = _Phase.downloading;
          _progress = p;
        });
      },
      onError: (msg) {
        _dotsTimer?.cancel();
        if (mounted) setState(() {
          _phase = _Phase.error;
          _errorMsg = msg;
        });
      },
      onInstalling: () {
        _dotsTimer?.cancel();
        if (mounted) setState(() {
          _phase = _Phase.installing;
          _progress = 1.0;
        });
      },
    );
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _glowController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _dotsStr => '.' * _dots;

  String get _statusText {
    switch (_phase) {
      case _Phase.preparing:
        return 'Mempersiapkan$_dotsStr';
      case _Phase.needsPermission:
        return 'Menunggu izin instal';
      case _Phase.downloading:
        return 'Mengunduh pembaruan$_dotsStr';
      case _Phase.installing:
        return 'Membuka installer$_dotsStr';
      case _Phase.error:
        return 'Gagal mengunduh';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(whiteColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(logoSplasShcreen, width: 180),
              const Spacer(flex: 1),
              const Text(
                'Memperbarui Aplikasi',
                style: TextStyle(
                  color: Color(blackColor),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 40),

              if (_phase != _Phase.error && _phase != _Phase.needsPermission) ...[
                _ProgressBar(progress: _progress, glowAnim: _glowAnim),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusText,
                      style: const TextStyle(color: Color(grey2Color), fontSize: 13),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(blackColor),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              if (_phase == _Phase.needsPermission) ...[
                const Icon(Icons.lock_outline_rounded, color: Color(primaryColor), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Izinkan instal aplikasi dari sumber ini terlebih dahulu untuk melanjutkan update.',
                  style: TextStyle(color: Color(grey2Color), fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _openPermissionSettings,
                  icon: const Icon(Icons.settings_rounded, color: Color(primaryColor)),
                  label: const Text('Izinkan', style: TextStyle(color: Color(primaryColor), fontSize: 15)),
                ),
              ],

              if (_phase == _Phase.error) ...[
                const Icon(Icons.error_outline, color: Color(redColor), size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMsg,
                  style: const TextStyle(color: Color(grey2Color), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('update_screen_retry_update_download');
                    setState(() {
                      _phase = _Phase.preparing;
                      _progress = 0;
                    });
                    _dotsTimer = Timer.periodic(
                      const Duration(milliseconds: 450),
                      (_) { if (mounted) setState(() => _dots = (_dots + 1) % 4); },
                    );
                    _startDownload();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Color(primaryColor)),
                  label: const Text('Coba Lagi', style: TextStyle(color: Color(primaryColor), fontSize: 15)),
                ),
              ],

              const Spacer(flex: 3),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(warningColor), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Jangan tutup aplikasi selama pembaruan',
                    style: TextStyle(color: Color(warningColor), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Animation<double> glowAnim;

  const _ProgressBar({required this.progress, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                width: width,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(grey9Color),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (_, value, __) {
                  return AnimatedBuilder(
                    animation: glowAnim,
                    builder: (_, __) {
                      return Container(
                        width: (width * value).clamp(0, width),
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(primaryColor), Color(blue3Color)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(primaryColor).withValues(alpha: 0.5),
                              blurRadius: glowAnim.value,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
