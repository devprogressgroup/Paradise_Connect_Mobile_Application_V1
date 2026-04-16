import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_loading.dart';
import 'package:progress_group/features/auth/presentation/state/bloc/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/bloc/auth_state.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_snackbar.dart';
import '../../state/bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 1;
  
  bool _isObscure = true;
  bool _isObscure2 = true;

  final _whatsaappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(4, (_) => TextEditingController());

  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _whatsappFN = FocusNode();
  final _passwordFN = FocusNode();
  final _confirmPasswordFN = FocusNode();



  void _forgotPassword() {
    final phone = _whatsaappController.text.trim();
    if (phone.isEmpty) {
      showSnackbar(context, "Nomor WhatsApp wajib diisi", isError: true);
      return;
    }
    context.read<AuthBloc>().add(ForgotPasswordEvent(phone));
  }

  void _handleAuthState(AuthState state) {
    if (state is AuthLoading) {
      showLoadingDialog(true, context);
      return;
    }

    hideLoadingDialog(true, context);
    if (state is AuthSuccess) {
      showSnackbar(context, state.message);
      setState(() {
        _step = 2;
      });
      print("OTP dikirim ke: ${state.message}");
    }
    if (state is AuthFailure) {
      showSnackbar(context, state.error, isError: true);
    }
  }  

  @override
  void dispose() {
    _whatsaappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

     return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: Scaffold(
        body: Container(
          height: size.height,
          width: size.width,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          color: Color(backgroundColor),
          child: Container(
            child: Center(
              child: _step == 1 ? _buildForgotPass() : _buildResetPass()
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPass(){
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08),blurRadius: 20,offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reset Password',textAlign: TextAlign.center,style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700,letterSpacing: 0,color: Color(blue2Color))),
            const SizedBox(height: 32),
            Text("Verification Code",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Color(grey2Color))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(primaryColor),width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Colors.grey, width: 1)),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 3) {
                          FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      } else {
                        if (index > 0) {
                          FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text("New Password",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Color(grey2Color))),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFN,
              onTapOutside: (event) => _passwordFN.unfocus(),
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                hintStyle: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(grey3Color)),
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(primaryColor),width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Colors.grey, width: 1)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Confirm Password",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Color(grey2Color))),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFN,
              onTapOutside: (event) => _confirmPasswordFN.unfocus(),
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                hintStyle: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(grey3Color)),
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: Icon(_isObscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () {
                    setState(() {
                      _isObscure2 = !_isObscure2;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(primaryColor),width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Colors.grey, width: 1)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(primaryColor),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Send Request',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
            ),
          ],
        ),
    );
  }

  Widget _buildForgotPass(){
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(32),
         boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.08),blurRadius: 20,offset: const Offset(0, 10))
         ],
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           // Header 
           const Text('Forgot Password',textAlign: TextAlign.center,style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700,letterSpacing: 0,color: Color(blue2Color))),
           Text("Enter your WhatsApp number and we will send you a code to reset your password",textAlign: TextAlign.center, style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Color(grey2Color))),
           const SizedBox(height: 32),
           Text("WhatsApp Number",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700,color: Color(grey2Color))),
           const SizedBox(height: 10),
           TextFormField(
             controller: _whatsaappController,
             focusNode: _whatsappFN,
             onTapOutside: (event) => _whatsappFN.unfocus(),
             keyboardType: TextInputType.numberWithOptions(),
             decoration: InputDecoration(
               hintText: '62 812-3456-7890',
               hintStyle: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(grey3Color)),
               filled: true,
               fillColor: Colors.grey[50],
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
               focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(primaryColor),width: 1.5)),
               errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
               focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
               disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Colors.grey, width: 1)),
             ),
           ),
           const SizedBox(height: 20),
           const SizedBox(height: 32),
           ElevatedButton(
             onPressed: () {
               _forgotPassword();
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Color(primaryColor),
               foregroundColor: Colors.white,
               minimumSize: const Size(double.infinity, 56),
               elevation: 0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             ),
             child: const Text('Send Request',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
           ),
         ],
       ),
    );
  }

}
