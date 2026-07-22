


import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_header.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final bool showHeader;

  const WebViewPage({super.key, required this.url, required this.title, this.showHeader = true});

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
  late final html.IFrameElement _iframe;
  bool _isLoading = true;
  bool _showFallbackBanner = false;
  Timer? _timeoutTimer;
  html.EventListener? _navigateListener;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewId = 'webview-iframe-$_counter';

    final embedUrl = _toEmbedUrl(widget.url);

    _iframe = html.IFrameElement()
      ..src = embedUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute('allow', 'autoplay; fullscreen');

    _iframe.onLoad.listen((_) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    });

    _startTimeout(embedUrl);

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => _iframe);

    _setupOpenInterceptor();
  }

  void _startTimeout(String url) {
    _timeoutTimer?.cancel();
    final isDriveOrPdf = _extractFolderId(url) != null ||
        _extractDriveId(url) != null ||
        widget.isPdf;
    _timeoutTimer = Timer(Duration(seconds: isDriveOrPdf ? 12 : 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _showFallbackBanner = true;
        });
      }
    });
  }

  void _setupOpenInterceptor() {
    
    
    
    js.context.callMethod('eval', ['''
      if (!window.__flutterNavIntercepted) {
        window.__flutterNavIntercepted = true;
        window.open = function(url, name, features) {
          window.dispatchEvent(new CustomEvent('__flutter_navigate', {
            detail: { url: url }
          }));
          return { closed: false, close: function(){}, focus: function(){} };
        };
      }
    ''']);

    _navigateListener = (html.Event event) {
      if (event is html.CustomEvent && mounted) {
        final detail = event.detail;
        final url = (js.JsObject.fromBrowserObject(detail)['url'])?.toString();
        if (url != null && url.isNotEmpty) {
          final embedUrl = _toEmbedUrl(url);
          _iframe.src = embedUrl;
          setState(() {
            _isLoading = true;
            _showFallbackBanner = false;
          });
          _startTimeout(embedUrl);
        }
      }
    };

    html.window.addEventListener('__flutter_navigate', _navigateListener!);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    if (_navigateListener != null) {
      html.window.removeEventListener('__flutter_navigate', _navigateListener!);
    }
    super.dispose();
  }

  
  
  
  
  
  String _toEmbedUrl(String url) {
    final youtubeId = _extractYoutubeId(url);
    if (youtubeId != null) {
      return 'https://www.youtube.com/embed/$youtubeId?rel=0';
    }
    final folderId = _extractFolderId(url);
    if (folderId != null) {
      return 'https://drive.google.com/embeddedfolderview?id=$folderId#list';
    }
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

  String? _extractYoutubeId(String url) {
    final m = RegExp(
      r'(?:youtube(?:-nocookie)?\.com\/(?:watch\?v=|shorts\/|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(url);
    return m?.group(1);
  }

  String? _extractFolderId(String url) {
    final m = RegExp(r'/folders/([a-zA-Z0-9_-]+)').firstMatch(url);
    return m?.group(1);
  }

  String? _extractDriveId(String url) {
    final m = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m != null) return m.group(1);
    final m2 = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m2 != null) return m2.group(1);
    return null;
  }

  void _openInNewTab() => html.window.open(widget.url, '_blank');

  void _shareUrl() => Share.share(widget.url, subject: widget.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.showHeader)
            SafeArea(
              bottom: false,
              child: customHeader(
                context,
                widget.title,
                isBack: true,
                colorTitle: Color(blackColor),
                colorIconLeft: Color(primaryColor),
                colorBack: Color(primaryColor),
                iconLeft: Icons.share,
                iconLeftOnTap: _shareUrl,
              ),
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
    );
  }
}
