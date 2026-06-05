import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../state/landing_page_cubit.dart';
import '../state/landing_page_state.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  WebViewController? _controller;
  bool _pageLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<LandingPageCubit>().fetchUrl();
  }

  void _initController(String url) {
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
    return SafeArea(
      bottom: false,
      child: BlocBuilder<LandingPageCubit, LandingPageState>(
        builder: (context, state) {
          if (state is LandingPageLoading || state is LandingPageInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LandingPageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<LandingPageCubit>().fetchUrl(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is LandingPageLoaded) {
            if (_controller == null) {
              _initController(state.url);
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller!),
                if (_pageLoading) const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
