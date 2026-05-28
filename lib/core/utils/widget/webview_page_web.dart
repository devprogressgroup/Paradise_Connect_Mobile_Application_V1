// Web-only: tampilkan URL (PDF/website) via <iframe>.
// flutter_pdfview, path_provider, webview_flutter tidak support web.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'custom_header.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, required this.title});

  bool get isPdf {
    final u = url.toLowerCase();
    return u.endsWith('.pdf') || u.contains('.pdf?');
  }

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static int _counter = 0;
  late final String _viewId;
  bool _isLoading = true;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewId = 'webview-iframe-$_counter';

    final embedUrl = _toEmbedUrl(widget.url);

    final iframe = html.IFrameElement()
      ..src = embedUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute('allow', 'autoplay; fullscreen');

    iframe.onLoad.listen((_) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    });

    // Drive /preview dan Docs viewer butuh waktu lebih lama
    final isDriveOrPdf = _extractDriveId(widget.url) != null || widget.isPdf;
    final timeout = isDriveOrPdf ? 12 : 8;
    _timeoutTimer = Timer(Duration(seconds: timeout), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _showFallbackBanner = true;
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // Prioritas:
  // 1. Google Drive URL (/d/ID) → /preview (support semua tipe file Drive)
  // 2. URL dengan ekstensi .pdf → Google Docs viewer
  // 3. URL biasa → embed langsung di iframe
  String _toEmbedUrl(String url) {
    final driveId = _extractDriveId(url);
    if (driveId != null) {
      return 'https://drive.google.com/file/d/$driveId/preview';
    }
    if (widget.isPdf) {
      final encoded = Uri.encodeComponent(url);
      return 'https://docs.google.com/viewer?url=$encoded&embedded=true';
    }
    return url;
  }

  String? _extractDriveId(String url) {
    final m = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m != null) return m.group(1);
    final m2 = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m2 != null) return m2.group(1);
    return null;
  }

  void _openInNewTab() => html.window.open(widget.url, '_blank');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: customHeader(
              context,
              widget.title,
              isBack: true,
              colorTitle: Color(blackColor),
              colorIconLeft: Color(primaryColor),
              colorBack: Color(primaryColor),
              iconLeft: Icons.open_in_new,
              iconLeftOnTap: _openInNewTab,
            ),
          ),

          // Banner hanya muncul saat gagal load
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
                      'Tampilan gagal dimuat. Buka di tab baru untuk melihat file.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openInNewTab,
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
            child: HtmlElementView(viewType: _viewId),
          ),
        ],
      ),
    );
  }
}
