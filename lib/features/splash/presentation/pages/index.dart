import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/proxy_cipher.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_group/core/utils/web_debug_util.dart' as web_debug;
import 'package:progress_group/core/services/analytics_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('splash');
    _checkToken();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _checkToken() async {
    
    final prefs = await SharedPreferences.getInstance();
    final token = ProxyCipher.decryptString(prefs.getString('auth_token'));
    web_debug.logDebugError('[Splash] token: ${token != null && token.isNotEmpty ? 'ada (${token.length} chars)' : 'tidak ada'}');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      
      
      
      context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true));

      _fallbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && context.read<ProfileBloc>().state is ProfileLoading) {
          web_debug.logDebugError('[Splash] fallback timer: profile masih loading → go /login');
          context.go('/login');
        }
      });
    } else {
      web_debug.logDebugError('[Splash] → no token, go /login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        web_debug.logDebugError('[Splash] ProfileBloc state: ${state.runtimeType}');
        if (state is ProfileLoaded) {
          web_debug.logDebugError('[Splash] ProfileLoaded: ${state.profile.username} (role ${state.profile.userRoleId}) → go /');
          context.read<AuthBloc>().add(FetchPermissionsEvent());
          AppRouter.authNotifier.value = true;
          context.go('/');
        } else if (state is ProfileFailure) {
          web_debug.logDebugError('[Splash] ProfileFailure: ${state.message} → hapus token, go /login');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          await prefs.setBool('is_auto_login', false);
          if (mounted) context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: Color(greySplash),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                kIsWeb ? logoSplasShcreenGif : logoSplasShcreenGif,
                width: 300,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
