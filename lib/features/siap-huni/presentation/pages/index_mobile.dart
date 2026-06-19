import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:progress_group/core/network/api_constants.dart';

class SiapHuniPage extends StatefulWidget {
  const SiapHuniPage({super.key});

  @override
  State<SiapHuniPage> createState() => _SiapHuniPageState();
}

class _SiapHuniPageState extends State<SiapHuniPage> {
  WebViewController? _controller;
  bool _pageLoading = false;

  @override
  void initState() {
    super.initState();
    final url = ApiConstants.siapHuniUrl;
    if (url.isEmpty) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _pageLoading = true),
        onPageFinished: (_) => setState(() => _pageLoading = false),
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SafeArea(
        bottom: false,
        child: Center(child: Text('URL belum tersedia')),
      );
    }
    return SafeArea(
      bottom: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller!),
          if (_pageLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
