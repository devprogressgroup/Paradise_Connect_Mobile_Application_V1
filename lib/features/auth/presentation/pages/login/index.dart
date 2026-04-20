import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';

import '../../../../../core/utils/widget/custom_loading.dart';
import '../../../../../core/utils/widget/custom_snackbar.dart';
import '../../state/bloc/auth_bloc.dart';
import '../../state/bloc/auth_event.dart';
import '../../state/bloc/auth_state.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loadingDialogShown = false;
  bool _rememberMe = false;
  bool _isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFN = FocusNode();
  final _passwordFN = FocusNode();

  StreamSubscription<AuthState>? _authSubscription;


  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckRememberMeEvent());
  }



  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      showSnackbar(context, "Email & Password wajib diisi", isError: true);
      return;
    }

    _authSubscription?.cancel();

    final bloc = context.read<AuthBloc>();
    _authSubscription = bloc.stream.listen((state) {
      if (state is AuthLoading) {
        showLoadingDialog(_loadingDialogShown, context);
        return;
      }

      _authSubscription?.cancel();
      hideLoadingDialog(_loadingDialogShown, context);

      if (state is AuthSuccess) {
        showSnackbar(context, state.message);
        Future.microtask(() => context.go('/'));
      }
      if (state is AuthFailure) {
        showSnackbar(context, state.error, isError: true);
        print('AUTH FAILURE: ${state.error}');
      }
    });

    bloc.add(LoginEvent(email, password, rememberMe: _rememberMe));
  }



  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is RememberMeLoaded,
      listener: (context, state) {
        if (state is RememberMeLoaded) {
          _emailController.text = state.username;
          _passwordController.text = state.password;
          setState(() {
            _rememberMe = true;
          });
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
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
                      const Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: Color(blue2Color),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Email Address",
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
                        decoration: InputDecoration(
                          hintText: 'youremail@gmail.com',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(grey3Color),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey4Color),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey4Color),
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
                              color: Colors.grey,
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
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          filled: true,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(grey3Color),
                          ),
                          fillColor: Colors.grey[50],
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
                              color: Color(grey4Color),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Color(grey4Color),
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
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _rememberMe
                                          ? Color(blackColor)
                                          : Colors.grey,
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
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed("forgot-password", extra: 1);
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(grey5Color),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          _login();
                          // context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(primaryColor),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
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
