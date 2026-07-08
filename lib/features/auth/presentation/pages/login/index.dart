import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../../core/utils/web_debug_util.dart' as web_debug;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:local_auth/local_auth.dart';
import 'package:progress_group/core/utils/widget/env_swither.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/utils/widget/custom_snackbar.dart';
import '../../state/auth/auth_bloc.dart';
import '../../state/auth/auth_event.dart';
import '../../state/auth/auth_state.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loadingDialogShown = false;
  bool _rememberMe = false;
  bool _isObscure = true;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFN = FocusNode();
  final _passwordFN = FocusNode();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckRememberMeEvent());
    context.read<AuthBloc>().add(CheckBiometricEnabledEvent());
    _loadAvailableBiometrics();
  }

  Future<void> _loadAvailableBiometrics() async {
    if (kIsWeb) return;
    final isSupported = await _auth.isDeviceSupported();
    if (!isSupported) return;
    final biometrics = await _auth.getAvailableBiometrics();
    if (mounted) setState(() => _availableBiometrics = biometrics);
  }

  IconData get _biometricIcon {
    if (_availableBiometrics.contains(BiometricType.face)) return Icons.face_unlock_outlined;
    if (_availableBiometrics.contains(BiometricType.iris)) return Icons.remove_red_eye_outlined;
    return Icons.fingerprint;
  }

  String get _biometricReason {
    if (_availableBiometrics.contains(BiometricType.face)) return 'Scan wajah untuk login';
    if (_availableBiometrics.contains(BiometricType.iris)) return 'Scan iris untuk login';
    return 'Scan fingerprint untuk login';
  }


  Future<void> _loginWithBiometric() async {
    try {
      final isSupported = await _auth.isDeviceSupported();

      if (!isSupported) {
        if (context.mounted) showSnackbar(context, "Perangkat ini tidak mendukung autentikasi biometrik", isError: true);
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: _biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) return;

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        if (context.mounted) showSnackbar(context, "Login manual sekali dulu untuk menyimpan kredensial", isError: true);
        return;
      }

      if (!context.mounted) return;
      context.read<AuthBloc>().add(
        LoginEvent(email, password, rememberMe: true),
      );
    } catch (e) {
      if (context.mounted) showSnackbar(context, "Biometrik gagal: $e", isError: true);
    }
  }

  

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      showSnackbar(context, "Email & Password wajib diisi", isError: true);
      return;
    }

    // Kalau biometrik aktif, selalu simpan credentials (tidak perlu Remember Me)
    context.read<AuthBloc>().add(LoginEvent(email, password, rememberMe: _rememberMe || _biometricEnabled));
  }



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          if (!_loadingDialogShown) {
            _loadingDialogShown = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          }
          return;
        }

        if (_loadingDialogShown) {
          _loadingDialogShown = false;
          if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }

        if (state is BiometricEnabledLoaded) {
          setState(() => _biometricEnabled = state.enabled);
        } else if (state is RememberMeLoaded) {
          _emailController.text = state.username;
          _passwordController.text = state.password;
          setState(() => _rememberMe = true);
        } else if (state is AuthFailure) {
          // debugPrint('AuthFailure: ${state.error}');
           showSnackbar(context, state.error, isError: true);
        }
      },
      child: Scaffold(
        body: Container(
          height: size.height,
          width: size.width,
          color: Color(backgroundColor),
          child: Container(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  decoration: BoxDecoration(
                    color: Color(whiteColor),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Color(blackColor).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      GestureDetector(
                        onTap: () => showEnvSwitcher(context),
                        child: const Text(
                          'Sign In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: Color(blue2Color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Username / Email / Phone",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(grey2Color),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFN,
                        onTapOutside: (event) => _emailFN.unfocus(),
                        onChanged: (_) {
                          if (_rememberMe) {
                            setState(() => _rememberMe = false);
                            context.read<AuthBloc>().add(ClearRememberMeEvent());
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'youremail@gmail.com',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(grey4Color),
                          ),
                          filled: true,
                          fillColor: Color(greyShade50),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey8Color),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey8Color),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(primaryColor),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(redPeriodColor),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(redPeriodColor),
                              width: 1.5,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(greyShade500),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(grey2Color),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFN,
                        onTapOutside: (event) => _passwordFN.unfocus(),
                        obscureText: _isObscure,
                        onChanged: (_) {
                          if (_rememberMe) {
                            setState(() => _rememberMe = false);
                            context.read<AuthBloc>().add(ClearRememberMeEvent());
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          filled: true,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(grey4Color),
                          ),
                          fillColor: Color(greyShade50),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey8Color),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey8Color),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(primaryColor),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(redPeriodColor),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(redPeriodColor),
                              width: 1.5,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(greyShade500),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                    if (!_rememberMe) {
                                      context.read<AuthBloc>().add(ClearRememberMeEvent());
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: Color(transparentColor),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _rememberMe
                                            ? Color(blackColor)
                                            : Color(greyShade500),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _rememberMe
                                        ? Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Color(primaryColor),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Color(blue2Color),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed("forgot-password", extra: 1);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(grey3Color),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 16),
                      // // Env badge
                      // Center(
                      //   child: ValueListenableBuilder<AppEnvironment>(
                      //     valueListenable: ApiConstants.envNotifier,
                      //     builder: (_, env, __) {
                      //       final isProd = env == AppEnvironment.production;
                      //       final color = isProd ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
                      //       return GestureDetector(
                      //         onTap: _showEnvSwitcher,
                      //         child: Container(
                      //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //           decoration: BoxDecoration(
                      //             color: color.withValues(alpha: 0.1),
                      //             borderRadius: BorderRadius.circular(20),
                      //             border: Border.all(color: color.withValues(alpha: 0.4)),
                      //           ),
                      //           child: Row(
                      //             mainAxisSize: MainAxisSize.min,
                      //             children: [
                      //               Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      //               const SizedBox(width: 6),
                      //               Text(
                      //                 isProd ? 'Production' : 'Development',
                      //                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      //               ),
                      //               const SizedBox(width: 4),
                      //               Icon(Icons.unfold_more_rounded, size: 14, color: color),
                      //             ],
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Row(
                          children: [
                            Expanded( // 🔥 WAJIB biar gak overflow
                              child: ElevatedButton(
                                onPressed: () {
                                  _login();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:ApiConstants.envLabel =="Production"? Color(primaryColor):Color(redColor),
                                  foregroundColor: Color(whiteColor),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            if (_biometricEnabled && !kIsWeb) ...[
                              const SizedBox(width: 12),
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: Color(primaryColor),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  onPressed: _loginWithBiometric,
                                  icon: Icon(
                                    _biometricIcon,
                                    color: Color(whiteColor),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle( fontSize: 12, color: Color(greyShade500)),),
                              GestureDetector(
                                onTap: () async {
                                 context.pushNamed("forgot-password", extra: {'step': 1, 'isRegister': true});
                                },
                                child: Text("Sign Up", style: TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: Color(primaryColor), decoration: TextDecoration.underline, decorationColor: Color(primaryColor), decorationThickness: 1,),textAlign: TextAlign.center,)),
                            ],
                          ),
                        
                          GestureDetector(
                            onTap: () async {
                              final msg = ApiConstants.loginHelpMessage.isNotEmpty
                                  ? ApiConstants.loginHelpMessage
                                  : 'Halo, saya mengalami masalah saat login di aplikasi Progress Group. Mohon bantuannya.';
                              final uri = Uri(
                                scheme: 'https',
                                host: 'wa.me',
                                path: '/6281574966666',
                                queryParameters: {'text': msg},
                              );
                              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            child: Text("Help",style: TextStyle(
                                color: Color(grey3Color),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),)),
                        ],
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: web_debug.showDebugPanel,
                          child: Text(
                            'Debug Info',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(greyShade400),
                            ),
                          ),
                        ),
                      ],
                      // ValueListenableBuilder<AppEnvironment>(
                      //   valueListenable: ApiConstants.envNotifier,
                      //   builder: (_, env, __) => Text(
                      //     '${ApiConstants.envLabel} • ${ApiConstants.baseUrl}',
                      //     textAlign: TextAlign.center,
                      //     style: TextStyle(
                      //       fontSize: 11,
                      //       color: env == AppEnvironment.production
                      //           ? Color(greyShade500)
                      //           : Color(orange700Color),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
