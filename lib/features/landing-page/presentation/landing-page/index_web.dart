// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import '../state/landing_page_cubit.dart';
import '../state/landing_page_state.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static int _counter = 0;
  String? _viewId;
  String _fullUrl = '';
  bool _isLoading = true;
  bool _showFallbackBanner = false;
  bool _showWaBlockedBanner = false;
  Timer? _timeoutTimer;
  Timer? _pollTimer;
  html.IFrameElement? _iframe;
  bool _initialLoadDone = false;
  bool _iframeResetting = false;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    String? username;
    String? roleName;
    if (profileState is ProfileLoaded) {
      username = profileState.profile.username;
      roleName = profileState.profile.userRoleName;
    }
    context.read<LandingPageCubit>().fetchUrl(username: username, roleName: roleName);
  }

  bool _checkIframeAccessible() {
    try {
      final dynamic win = _iframe?.contentWindow;
      if (win == null) return false;
      final dynamic loc = win.location;
      final String href = (loc.href as String?) ?? '';
      if (href.isEmpty) return false;
      debugPrint('[LandingPage WEB NAV] iframe accessible href: $href');
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleExternalNavDetected() {
    if (!mounted || _iframeResetting) return;
    _pollTimer?.cancel();
    _iframeResetting = true;
    setState(() => _showWaBlockedBanner = true);
    _iframe?.src = _fullUrl;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _iframeResetting = false;
        _startPoll();
      }
    });
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _iframeResetting || !_initialLoadDone) return;
      if (_checkIframeAccessible()) _handleExternalNavDetected();
    });
  }

  void _initIframe(String url) {
    _fullUrl = url;
    _counter++;
    _viewId = 'landing-page-iframe-$_counter';
    _isLoading = true;
    _showFallbackBanner = false;
    _initialLoadDone = false;
    _iframeResetting = false;

    _iframe = html.IFrameElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute('allow', 'autoplay; fullscreen');

    _iframe!.onLoad.listen((_) {
      _timeoutTimer?.cancel();

      if (_iframeResetting) return;

      if (!_initialLoadDone) {
        _initialLoadDone = true;
        if (mounted) setState(() => _isLoading = false);
        _startPoll();
        return;
      }

      if (_checkIframeAccessible()) _handleExternalNavDetected();
    });

    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _showFallbackBanner = true;
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (_) => _iframe!);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocConsumer<LandingPageCubit, LandingPageState>(
        listenWhen: (prev, curr) => curr is LandingPageError && prev is! LandingPageError,
        listener: (context, state) {
          if (state is LandingPageError) {
            // debugPrint('LandingPageError: ${state.message}');
          }
        },
        builder: (context, state) {
          if (state is LandingPageLoading || state is LandingPageInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LandingPageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Gagal memuat halaman', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<LandingPageCubit>().fetchUrl(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is LandingPageLoaded) {
            if (_viewId == null || _fullUrl != state.url) {
              _initIframe(state.url);
            }
            return Column(
              children: [
                if (_showWaBlockedBanner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFFE8F5E9),
                    child: Row(
                      children: [
                        const Icon(Icons.chat, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Link WhatsApp tidak bisa dibuka di sini.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => html.window.open(_fullUrl, '_blank'),
                          icon: const Icon(Icons.open_in_browser, size: 14),
                          label: const Text('Buka di browser', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showWaBlockedBanner = false),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.close, size: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_showFallbackBanner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFFFFF8E1),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tampilan gagal dimuat. Buka di tab baru untuk melihat halaman.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => html.window.open(_fullUrl, '_blank'),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Buka', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                Expanded(
                  child: HtmlElementView(viewType: _viewId!),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
