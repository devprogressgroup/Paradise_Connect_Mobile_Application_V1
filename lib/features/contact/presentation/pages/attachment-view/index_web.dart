



import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';

class AttachmentWebViewPage extends StatefulWidget {
  final String url;

  const AttachmentWebViewPage({super.key, required this.url});

  @override
  State<AttachmentWebViewPage> createState() => _AttachmentWebViewPageState();
}

class _AttachmentWebViewPageState extends State<AttachmentWebViewPage> {
  static int _counter = 0;
  late final String _viewId;
  late final String _previewUrl;
  late final String _openUrl;

  bool _isLoading = true;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('attachment_view');
    _counter++;
    _viewId = 'attachment-iframe-$_counter';
    _previewUrl = _toPreviewUrl(widget.url);
    _openUrl = _toOpenUrl(widget.url);

    final iframe = html.IFrameElement()
      ..src = _previewUrl
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

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  String _toPreviewUrl(String url) {
    final id = _extractId(url);
    if (id != null) return 'https://drive.google.com/file/d/$id/preview';
    return url;
  }

  String _toOpenUrl(String url) {
    final id = _extractId(url);
    if (id != null) return 'https://drive.google.com/file/d/$id/view';
    return url;
  }

  String? _extractId(String url) {
    final m = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m != null) return m.group(1);
    final m2 = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m2 != null) return m2.group(1);
    return null;
  }

  void _openInNewTab() {
    AnalyticsService.logEvent('attachment_view_open_in_new_tab');
    html.window.open(_openUrl, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              'Preview Attachment',
              isBack: true,
              colorBack: const Color(primaryColor),
            ),

            
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
                        'Tampilan gagal dimuat. Buka di tab baru untuk melihat file.',
                        style: TextStyle(fontSize: 11, color: Color(blackColor).withAlpha(87)),
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
                backgroundColor: Color(transparentColor),
                valueColor: AlwaysStoppedAnimation<Color>(Color(primaryColor)),
              ),

            Expanded(
              child: HtmlElementView(viewType: _viewId),
            ),
          ],
        ),
      ),
    );
  }
}
