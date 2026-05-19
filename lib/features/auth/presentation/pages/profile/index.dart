import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/core/network/api_constants.dart';

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
          return buildProfileShimmer();
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(GetProfileEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                  user.photo!.startsWith('http') 
                                    ? user.photo! 
                                    : "${ApiConstants.storageUrl}/${user.photo}",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                        radius: 27,
                                        backgroundColor: Color(primaryColor),
                                        child: Icon(Icons.person, color: Colors.white, size: 37));
                                  },
                                )
                              : CircleAvatar(
                                  radius: 27,
                                  backgroundColor: Color(primaryColor),
                                  child: Icon(Icons.person, color: Colors.white, size: 37),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            if (user.positionName != null && user.positionName!.isNotEmpty)
                              Text(user.positionName!, style: const TextStyle(fontSize: 14, color: Colors.blueAccent)),
                            Text(user.permissionScope, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    Text("NIK Number : ${user.nikNumber}"),
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
                    // if (user.salesRoles.isNotEmpty) ...[
                    //   _label("Atasan"),
                    //   const SizedBox(height: 6),
                    //   ...user.salesRoles.map((role) => _buildAtasanChain(role)).toList(),
                    //   const SizedBox(height: 12),
                    // ],
                    // if (user.subordinates.isNotEmpty) ...[
                    //   _label("Bawahan"),
                    //   const SizedBox(height: 6),
                    //   ...user.subordinates.map((sub) => _buildHierarchyNode(sub, isAtasan: false)).toList(),
                    //   const SizedBox(height: 12),
                    // ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: customButton(() {}, "Submit")),
                        const SizedBox(width: 20),
                        Expanded(
                          child: customButton(
                            () {
                              context.read<AuthBloc>().add(LogoutEvent());
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
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // Widget _buildAtasanChain(dynamic node) {
  //   // 1. Flatten the linked list of parents
  //   List<dynamic> chain = [];
  //   dynamic current = node;
  //   while (current != null) {
  //     chain.add(current);
  //     current = current.parent;
  //   }
  //   // 2. Reverse the list so the highest position is first
  //   chain = chain.reversed.toList();

  //   // 3. Build the widgets recursively from the top down
  //   return _buildAtasanNode(chain, 0);
  // }

  // Widget _buildAtasanNode(List<dynamic> chain, int index) {
  //   if (index >= chain.length) return const SizedBox();

  //   var node = chain[index];
  //   bool isLast = index == chain.length - 1;

  //   Widget titleContent = Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(node.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  //       if (node.positionName != null && node.positionName!.isNotEmpty)
  //         Text(node.positionName!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
  //     ],
  //   );

  //   if (isLast) {
  //     return Padding(
  //       padding: EdgeInsets.only(left: index * 16.0, bottom: 8.0, top: 4.0),
  //       child: Row(
  //         children: [
  //           Icon(Icons.person_outline, size: 20, color: Color(primaryColor)),
  //           const SizedBox(width: 8),
  //           Expanded(child: titleContent),
  //         ],
  //       ),
  //     );
  //   }

  //   return Padding(
  //     padding: EdgeInsets.only(left: index == 0 ? 0 : 16.0),
  //     child: Theme(
  //       data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //       child: ExpansionTile(
  //         initiallyExpanded: true,
  //         tilePadding: EdgeInsets.zero,
  //         childrenPadding: EdgeInsets.zero,
  //         leading: Icon(Icons.people_alt_outlined, color: Color(primaryColor)),
  //         title: titleContent,
  //         children: [_buildAtasanNode(chain, index + 1)],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildHierarchyNode(dynamic node, {bool isAtasan = false, int depth = 0}) {
  //   // Determine children (Subordinates only now, as Atasan has its own builder)
  //   List children = node.subordinates ?? [];

  //   Widget titleContent = Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(node.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  //       if (node.positionName != null && node.positionName!.isNotEmpty)
  //         Text(node.positionName!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
  //     ],
  //   );

  //   if (children.isEmpty) {
  //     return Padding(
  //       padding: EdgeInsets.only(left: depth * 16.0, bottom: 8.0, top: 4.0),
  //       child: Row(
  //         children: [
  //           Icon(Icons.person_outline, size: 20, color: Color(primaryColor)),
  //           const SizedBox(width: 8),
  //           Expanded(child: titleContent),
  //         ],
  //       ),
  //     );
  //   }

  //   return Padding(
  //     padding: EdgeInsets.only(left: depth * 16.0),
  //     child: Theme(
  //       data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //       child: ExpansionTile(
  //         tilePadding: EdgeInsets.zero,
  //         childrenPadding: EdgeInsets.zero,
  //         leading: Icon(Icons.people_alt_outlined, color: Color(primaryColor)),
  //         title: titleContent,
  //         children: children.map((child) => _buildHierarchyNode(child, isAtasan: isAtasan, depth: depth + 1)).toList(),
  //       ),
  //     ),
  //   );
  // }

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
            color: Color(grey4Color),
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
        color: Color(grey7Color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(grey8Color)),
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
        color: color ?? Color(grey8Color),
        width: width,
      ),
    );
  }
 Widget _label(String title){
    return Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(grey2Color)));
  }

}