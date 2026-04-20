import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController emailTC = TextEditingController();
  TextEditingController phoneTC = TextEditingController();
  TextEditingController passwordTC = TextEditingController();
  TextEditingController confirmPasswordTC = TextEditingController();

  FocusNode emailFN = FocusNode();
  FocusNode phoneFN = FocusNode();
  FocusNode passwordFN = FocusNode();
  FocusNode confirmPasswordFN = FocusNode();

  bool _isObscure = true;
  bool _isObscureConfirm = true;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetProfileEvent());
  }


  @override
  void dispose() {
    emailTC.dispose();
    phoneTC.dispose();
    passwordTC.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "My Profile", isBack: true, colorBack: Color(primaryColor), onBack: () => context.go('/')),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }


  Widget _buildBody() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProfileFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 10),
                customButton(() {
                  context.read<ProfileBloc>().add(GetProfileEvent());
                }, "Retry"),
              ],
            ),
          );
        }

        if (state is ProfileLoaded) {
          final user = state.profile;
          emailTC.text = user.email;
          phoneTC.text = user.phoneNumber;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PROFILE HEADER
                  Row(
                    children: [
                      ClipOval(
                        child: user.photo != null
                            ? Image.network(
                                user.photo!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Color(primaryColor).withOpacity(0.1),
                                child: Icon(Icons.person, color: Color(primaryColor), size: 30),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(user.permissionScope, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const Text("Team A", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  _label("Username"),
                  const SizedBox(height: 6),
                  _readonlyField(user.username),
                  const SizedBox(height: 12),
                  _label("Email"),
                  const SizedBox(height: 6),
                  _inputField(
                    controller: emailTC,
                    focusNode: emailFN,
                    hint: 'youremail@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _label("Phone Number"),
                  const SizedBox(height: 6),
                  _inputField(
                    controller: phoneTC,
                    focusNode: phoneFN,
                    hint: '08123456789',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _label("Password"),
                  const SizedBox(height: 6),
                  _inputField(
                    controller: passwordTC,
                    focusNode: passwordFN,
                    hint: '••••••••',
                    obscure: _isObscure,
                    suffix: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label("Confirm Password"),
                  const SizedBox(height: 6),
                  _inputField(
                    controller: confirmPasswordTC,
                    focusNode: confirmPasswordFN,
                    hint: '••••••••',
                    obscure: _isObscureConfirm,
                    suffix: IconButton(
                      icon: Icon(_isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _isObscureConfirm = !_isObscureConfirm;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: customButton(() {}, "Submit")),
                      const SizedBox(width: 20),
                      Expanded(
                        child: customButton(
                          () async {
                            final prefs = await SharedPreferences.getInstance();
                            final localDataSource = AuthLocalDataSourceImpl(prefs);
                            await localDataSource.clearToken();
                            if (mounted) context.go('/login');
                          },
                          "Logout",
                          colorBg: Color(whiteColor),
                          colorText: Color(primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
  Widget _inputField({   required TextEditingController controller,   required FocusNode focusNode,   required String hint,   TextInputType? keyboardType,   bool obscure = false,   Widget? suffix, }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        onTapOutside: (_) => focusNode.unfocus(),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey[50],
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(grey3Color),
          ),
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _border(color: Color(primaryColor), width: 1.5),
        ),
      ),
    );
  }     

  Widget _readonlyField(String value) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(grey11Color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(grey4Color)),
      ),
      child: Text(
        value,
        style: TextStyle(color: Color(grey2Color)),
      ),
    );
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color ?? Color(grey4Color),
        width: width,
      ),
    );
  }
 Widget _label(String title){
    return Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(grey2Color)));
  }

}