import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'custom_header.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  bool get isPdf {
    final urlLower = url.toLowerCase();
    return urlLower.endsWith('.pdf') || urlLower.contains('.pdf?');
  }

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  String? _localFilePath;

  void _shareFile() {
    if (_localFilePath == null) return;
    Share.shareXFiles([XFile(_localFilePath!)], subject: widget.title);
  }

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
              iconLeft: widget.isPdf && _localFilePath != null ? Icons.share : null,
              iconLeftOnTap: _shareFile,
            ),
          ),
          Expanded(
            child: widget.isPdf
                ? PdfViewerWidget(
                    url: widget.url,
                    title: widget.title,
                    onFileReady: (path) => setState(() => _localFilePath = path),
                  )
                : WebViewerWidget(url: widget.url),
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
            style: const TextStyle(color: Colors.red),
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
        debugPrint('PDF page error $page : $e');
      },
    );
  }
}

class WebViewerWidget extends StatefulWidget {
  final String url;

  const WebViewerWidget({
    super.key,
    required this.url,
  });

  @override
  State<WebViewerWidget> createState() => _WebViewerWidgetState();
}

class _WebViewerWidgetState extends State<WebViewerWidget> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
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