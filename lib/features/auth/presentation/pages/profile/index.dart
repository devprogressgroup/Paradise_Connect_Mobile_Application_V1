import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';

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
                  child: Image.network(
                    "https://i.pravatar.cc/150?img=1",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Evan Dwi Saputro",style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Sales Executive",style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text("Team A",style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            _label("Username"),
            const SizedBox(height: 6),
            _readonlyField("Evan Dwi Saputro"),
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
              suffix: IconButton( icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
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
              suffix: IconButton( icon: Icon(_isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
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
                const SizedBox(width: 30),
                Expanded(child: customButton(() {}, "Logout", colorBg: Color(whiteColor), colorText: Color(primaryColor))),
              ],
            ),
          ],
        ),
      ),
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