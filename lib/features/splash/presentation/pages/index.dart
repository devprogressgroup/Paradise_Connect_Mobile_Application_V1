import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkToken();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _checkToken() async {
    // debugPrint('[Splash] _checkToken: start');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // debugPrint('[Splash] token: ${token != null && token.isNotEmpty ? 'ada (${token.length} chars)' : 'tidak ada'}');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // debugPrint('[Splash] → fetch profile');
      // forceRefresh: true agar saat re-entry (mis. setelah impersonate token swap)
      // profil di-fetch ulang dengan token baru, bukan ambil cache user sebelumnya.
      context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true));

      _fallbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && context.read<ProfileBloc>().state is ProfileLoading) {
          // debugPrint('[Splash] fallback timer: profile masih loading → go /login');
          context.go('/login');
        }
      });
    } else {
      // debugPrint('[Splash] → no token, go /login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        // debugPrint('[Splash] ProfileBloc state: ${state.runtimeType}');
        if (state is ProfileLoaded) {
          // debugPrint('[Splash] ProfileLoaded: ${state.profile.username} (role ${state.profile.userRoleId}) → go /');
          context.read<AuthBloc>().add(FetchPermissionsEvent());
          AppRouter.authNotifier.value = true;
          context.go('/');
        } else if (state is ProfileFailure) {
          // debugPrint('[Splash] ProfileFailure: ${state.message} → hapus token, go /login');
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
