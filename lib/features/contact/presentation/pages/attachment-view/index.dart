import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/constants/colors.dart';

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

    final fixedUrl = _convertDriveUrl(widget.url);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "Preview Attachment", isBack: true, colorBack: const Color(primaryColor)),
            
            if (isLoading)
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
    return buildAttachmentShimmer();
  }

  String _convertDriveUrl(String url) {
    // Handle /d/FILE_ID format
    final dRegex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final dMatch = dRegex.firstMatch(url);
    if (dMatch != null) {
      final fileId = dMatch.group(1);
      return "https://drive.google.com/file/d/$fileId/preview";
    }

    // Handle id=FILE_ID format (from uc?export=view or similar)
    final idRegex = RegExp(r'id=([a-zA-Z0-9_-]+)');
    final idMatch = idRegex.firstMatch(url);
    if (idMatch != null) {
      final fileId = idMatch.group(1);
      return "https://drive.google.com/file/d/$fileId/preview";
    }

    return url;
  }
}