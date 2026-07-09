import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';

class AttachmentWebViewPage extends StatefulWidget {
  final String url;

  const AttachmentWebViewPage({super.key, required this.url});

  @override
  State<AttachmentWebViewPage> createState() => _AttachmentWebViewPageState();
}

class _AttachmentWebViewPageState extends State<AttachmentWebViewPage> {
  late final WebViewController controller;

  bool isLoading = true;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('attachment_view');

    final fixedUrl = _convertDriveUrl(widget.url);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            setState(() {
              progress = p / 100;
            });
          },
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() => isLoading = false);
            // Google Drive's preview page sets user-scalable=no on its viewport meta
            // to drive its own in-page zoom UI, which blocks native pinch-to-zoom
            // inside our WebView. Override it so pinch gestures work as expected.
            controller.runJavaScript('''
              (function() {
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
              })();
            ''');
          },
          onWebResourceError: (error) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(fixedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "Preview Attachment", isBack: true, colorBack: const Color(primaryColor)),
            
            if (isLoading)
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Color(transparentColor),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(primaryColor)),
              ),

            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (isLoading && progress < 0.9)
                    _buildLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Color(primaryColor)),
      ),
    );
  }

  String _convertDriveUrl(String url) {
   
    final dRegex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final dMatch = dRegex.firstMatch(url);
    if (dMatch != null) {
      final fileId = dMatch.group(1);
      return "https://drive.google.com/file/d/$fileId/preview";
    }

   
    final idRegex = RegExp(r'id=([a-zA-Z0-9_-]+)');
    final idMatch = idRegex.firstMatch(url);
    if (idMatch != null) {
      final fileId = idMatch.group(1);
      return "https://drive.google.com/file/d/$fileId/preview";
    }

    return url;
  }
}
