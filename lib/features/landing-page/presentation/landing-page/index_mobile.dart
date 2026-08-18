import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import '../state/landing_page_cubit.dart';
import '../state/landing_page_state.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';

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
    AnalyticsService.logScreenView('landing_page');
    final profileState = context.read<ProfileBloc>().state;
    String? username;
    String? roleName;
    if (profileState is ProfileLoaded) {
      username = profileState.profile.username;
      roleName = profileState.profile.userRoleName;
    }
    context.read<LandingPageCubit>().fetchUrl(username: username, roleName: roleName);
  }

  void _initController(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _pageLoading = true),
        onPageFinished: (_) => setState(() => _pageLoading = false),
        onNavigationRequest: (request) {
          final url = request.url;
          debugPrint('[LandingPage NAV] $url');
          if (url.startsWith('whatsapp://') ||
              url.contains('wa.me') ||
              url.contains('api.whatsapp.com')) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocConsumer<LandingPageCubit, LandingPageState>(
        listenWhen: (prev, curr) => curr is LandingPageError && prev is! LandingPageError,
        listener: (context, state) {
          if (state is LandingPageError) {
           
          }
        },
        builder: (context, state) {
          if (state is LandingPageLoading || state is LandingPageInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LandingPageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(redAccentColor)),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      AnalyticsService.logEvent('landing_page_retry_load_landing');
                      context.read<LandingPageCubit>().fetchUrl();
                    },
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
