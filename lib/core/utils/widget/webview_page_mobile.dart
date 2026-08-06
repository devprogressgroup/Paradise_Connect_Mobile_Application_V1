import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/file_extension_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'custom_header.dart';
import 'custom_snackbar.dart';
import 'floating_download_overlay.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final bool showHeader;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
    this.showHeader = true,
  });

  bool get isPdf {
    final urlLower = url.toLowerCase();
    return urlLower.endsWith('.pdf') || urlLower.contains('.pdf?');
  }

  bool get isImage {
    final urlLower = url.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].any((ext) => urlLower.contains(ext));
  }

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool _isSharing = false;

  Future<void> _shareUrl() async {
    if (_isSharing) return;
    if (!widget.isPdf && !widget.isImage) {
      await Share.share(widget.url, subject: widget.title);
      return;
    }
    setState(() => _isSharing = true);
    try {
      final dir = await getTemporaryDirectory();
      final titleName = widget.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      final urlExt = extensionFromUrl(widget.url);
      var filePath = '${dir.path}/$titleName${urlExt ?? '.tmp'}';

      final response = await Dio().download(
        widget.url,
        filePath,
        options: Options(followRedirects: true, receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode != 200) {
        throw Exception('Download gagal ${response.statusCode}');
      }

      if (urlExt == null) {
        final resolvedExt = extensionFromContentDisposition(response.headers.value('content-disposition')) ??
            extensionFromContentType(response.headers.value('content-type')) ??
            (widget.isPdf ? '.pdf' : '.bin');
        final newPath = '${dir.path}/$titleName$resolvedExt';
        if (newPath != filePath) {
          await File(filePath).rename(newPath);
          filePath = newPath;
        }
      }

      await Share.shareXFiles([XFile(filePath)], subject: widget.title);
    } catch (_) {
      if (mounted) showSnackbar(context, 'Gagal mengunduh file, membagikan link saja', isError: true);
      await Share.share(widget.url, subject: widget.title);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

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
          Expanded(
            child: widget.isPdf
                ? PdfViewerWidget(
                    url: widget.url,
                    title: widget.title,
                    onFileReady: (_) {},
                  )
                : WebViewerWidget(url: widget.url, title: widget.title),
          ),
        ],
      ),
    );
  }
}

class PdfViewerWidget extends StatefulWidget {
  final String url;
  final String title;
  final void Function(String filePath)? onFileReady;

  const PdfViewerWidget({
    super.key,
    required this.url,
    required this.title,
    this.onFileReady,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  String? localPath;
  String? error;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    downloadPdf();
  }

  Future<void> downloadPdf() async {
    try {
      final dir = await getTemporaryDirectory();

      final safeName = widget.url.split('/').last.split('?').first;
      final ext = safeName.contains('.') ? '.${safeName.split('.').last}' : '.pdf';
      final titleName = widget.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      final filePath = '${dir.path}/$titleName$ext';

      final response = await Dio().download(
        widget.url,
        filePath,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            localPath = filePath;
          });
          widget.onFileReady?.call(filePath);
        }
      } else {
        throw Exception('Download gagal ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(redAccentColor)),
          ),
        ),
      );
    }

    if (localPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
            ),
            const SizedBox(height: 12),
            Text(
              progress > 0
                  ? '${(progress * 100).toInt()}%'
                  : 'Mengunduh PDF...',
            ),
          ],
        ),
      );
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: false,
      fitPolicy: FitPolicy.BOTH,
      onError: (e) {
        setState(() {
          error = e.toString();
        });
      },
      onPageError: (page, e) {
      
      },
    );
  }
}

class WebViewerWidget extends StatefulWidget {
  final String url;
  final String title;

  const WebViewerWidget({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewerWidget> createState() => _WebViewerWidgetState();
}

class _WebViewerWidgetState extends State<WebViewerWidget> {
  late final WebViewController controller;
  bool isLoading = true;
  BuildContext? _ctx;

  bool _isDownloadUrl(String url) =>
      url.contains('export=download') ||
      url.contains('uc?id=') ||
      url.contains('drive.usercontent.google.com/download');

  String? _extractYoutubeId(String url) {
    final m = RegExp(
      r'(?:youtube(?:-nocookie)?\.com\/(?:watch\?v=|shorts\/|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(url);
    return m?.group(1);
  }

  String _resolveLoadUrl(String url) {
    final youtubeId = _extractYoutubeId(url);
    if (youtubeId != null) {
      return 'https://www.youtube.com/embed/$youtubeId?rel=0';
    }
    return url;
  }

  String _filenameFromTitle() {
    final title = widget.title.trim();
   
    final urlLower = widget.url.toLowerCase();
    for (final ext in ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.pdf', '.zip']) {
      if (urlLower.contains(ext)) {
        final safe = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        return '$safe$ext';
      }
    }
    return '${title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.mp4';
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (_isDownloadUrl(url) && _ctx != null) {
              FloatingDownloadManager.show(
                context: _ctx!,
                url: url,
                filename: _filenameFromTitle(),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_resolveLoadUrl(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: controller),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
