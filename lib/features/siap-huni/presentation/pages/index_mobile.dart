import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/network/proxy_cipher.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';

class SiapHuniPage extends StatefulWidget {
  const SiapHuniPage({super.key});

  @override
  State<SiapHuniPage> createState() => _SiapHuniPageState();
}

class _SiapHuniPageState extends State<SiapHuniPage> {
  WebViewController? _controller;
  bool _pageLoading = false;
  bool _initialized = false;

  String _buildUrl(String fullName, String phone) {
    var base = ApiConstants.siapHuniUrl;
    if (base.isEmpty) return '';
    // Ambil base sampai 'key=' (inklusif), atau tambahkan suffix jika belum ada
    if (base.contains('key=')) {
      base = base.substring(0, base.indexOf('key=') + 4);
    } else {
      final connector = base.contains('?') ? '&' : '?';
      base = '${base}${connector}embed=1&key=';
    }
    final encrypted = ProxyCipher.encrypt({'nama_Sales': fullName, 'no_hp': phone});
    return '$base${Uri.encodeComponent(encrypted)}';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final profileState = context.read<ProfileBloc>().state;
    final String url;
    if (profileState is ProfileLoaded) {
      url = _buildUrl(profileState.profile.fullName, profileState.profile.phoneNumber);
    } else {
      url = ApiConstants.siapHuniUrl;
    }
    if (url.isNotEmpty) {
      debugPrint('[SiapHuni] URL: $url');
      _initController(url);
    }
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
