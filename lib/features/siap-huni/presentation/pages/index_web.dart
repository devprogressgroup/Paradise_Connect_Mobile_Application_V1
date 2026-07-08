
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/network/proxy_cipher.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/core/services/analytics_service.dart';

class SiapHuniPage extends StatefulWidget {
  const SiapHuniPage({super.key});

  @override
  State<SiapHuniPage> createState() => _SiapHuniPageState();
}

class _SiapHuniPageState extends State<SiapHuniPage> {
  static int _counter = 0;
  String? _viewId;
  String _fullUrl = '';
  bool _isLoading = true;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;
  bool _initialized = false;

  String _buildUrl(String fullName, String phone) {
    var base = ApiConstants.siapHuniUrl;
    if (base.isEmpty) return '';
   
    if (base.contains('key=')) {
      base = base.substring(0, base.indexOf('key=') + 4);
    } else {
      final connector = base.contains('?') ? '&' : '?';
      base = '${base}${connector}embed=1&key=';
    }
    final encrypted = ProxyCipher.encrypt({'nama_sales': fullName, 'no_hp': phone});
    return '$base${Uri.encodeComponent(encrypted)}';
  }

  void _initIframe(String url) {
    _fullUrl = url;
    _counter++;
    _viewId = 'siap-huni-iframe-$_counter';

    final iframe = html.IFrameElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute('allow', 'autoplay; fullscreen');

    iframe.onLoad.listen((_) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    });

    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _showFallbackBanner = true;
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (_) => iframe);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final profileState = context.read<ProfileBloc>().state;
    final String url;
    if (profileState is ProfileLoaded) {
      url = _buildUrl(profileState.profile.fullName, profileState.profile.phoneNumber);
    } else {
      url = ApiConstants.siapHuniUrl;
    }
    if (url.isNotEmpty) {
     
      _initIframe(url);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewId == null) {
      return const SafeArea(
        bottom: false,
        child: Center(child: Text('URL belum tersedia')),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (_showFallbackBanner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFFFF8E1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(orangeAccentColor)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tampilan gagal dimuat. Buka di tab baru untuk melihat halaman.',
                      style: TextStyle(fontSize: 11, color: Color(blackColor).withAlpha(87)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      AnalyticsService.logEvent('siap_huni_open_in_new_tab');
                      html.window.open(_fullUrl, '_blank');
                    },
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
              backgroundColor: Color(transparentColor),
              valueColor: AlwaysStoppedAnimation<Color>(Color(primaryColor)),
            ),
          Expanded(
            child: HtmlElementView(viewType: _viewId!),
          ),
        ],
      ),
    );
  }
}
