// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/api_constants.dart';

class SiapHuniPage extends StatefulWidget {
  const SiapHuniPage({super.key});

  @override
  State<SiapHuniPage> createState() => _SiapHuniPageState();
}

class _SiapHuniPageState extends State<SiapHuniPage> {
  static int _counter = 0;
  String? _viewId;
  bool _isLoading = true;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    final url = ApiConstants.siapHuniUrl;
    if (url.isEmpty) return;
    _initIframe(url);
  }

  void _initIframe(String url) {
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
                    onPressed: () => html.window.open(ApiConstants.siapHuniUrl, '_blank'),
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
      ),
    );
  }
}
