import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:progress_group/core/utils/web_debug_util.dart' as web_debug;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_group/core/network/proxy_cipher.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import 'package:progress_group/core/services/analytics_service.dart';

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
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  final LocalAuthentication _localAuth = LocalAuthentication();

  IconData get _biometricIcon {
    if (_availableBiometrics.contains(BiometricType.face)) return Icons.face_unlock_outlined;
    if (_availableBiometrics.contains(BiometricType.iris)) return Icons.remove_red_eye_outlined;
    return Icons.fingerprint;
  }

  String get _biometricSubtitle {
    if (_availableBiometrics.contains(BiometricType.face)) return 'Gunakan face ID untuk login';
    if (_availableBiometrics.contains(BiometricType.iris)) return 'Gunakan iris untuk login';
    if (_availableBiometrics.contains(BiometricType.fingerprint)) return 'Gunakan fingerprint untuk login';
    return 'Gunakan biometrik untuk login';
  }
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickPhoto() async {
    AnalyticsService.logEvent('profile_change_photo');
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedPhoto = picked;
        _selectedPhotoBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Isi controller langsung jika data sudah ada (hindari listener tidak terpanggil)
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      emailTC.text = profileState.profile.email;
      phoneTC.text = profileState.profile.phoneNumber;
    }

    context.read<ProfileBloc>().add(GetProfileEvent());
    context.read<AuthBloc>().add(CheckBiometricEnabledEvent());
    _loadAvailableBiometrics();
  }

  Future<void> _loadAvailableBiometrics() async {
    if (kIsWeb) return;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) return;
    final biometrics = await _localAuth.getAvailableBiometrics();
    if (mounted) setState(() => _availableBiometrics = biometrics);
  }

  Future<void> _onBiometricToggle(bool value) async {
    AnalyticsService.logEvent('profile_biometric_toggle');
    if (value) {
      try {
        final isSupported = await _localAuth.isDeviceSupported();
        if (!isSupported) {
          if (mounted) showSnackbar(context, "Perangkat ini tidak mendukung autentikasi biometrik", isError: true);
          return;
        }

        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Verifikasi biometrik untuk mengaktifkan fitur ini',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );

        if (!didAuthenticate) return;
      } catch (e) {
        if (mounted) showSnackbar(context, "Biometrik tidak tersedia di perangkat ini", isError: true);
        return;
      }

      // Minta password untuk simpan credentials
      final confirmed = await _showPasswordConfirmDialog();
      if (!confirmed) return;
    } else {
      if (mounted) context.read<AuthBloc>().add(SaveBiometricEnabledEvent(false));
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AnalyticsService.logEvent('profile_logout');
              web_debug.logDebugError('LogoutEvent dipicu dari: tombol Logout di halaman Profile');
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: Text('Logout', style: TextStyle(color: Color(redAccentColor))),
          ),
        ],
      ),
    );
  }

  void _submit(String originalEmail, String originalPhone) {
    AnalyticsService.logEvent('profile_submit_profile');
    final email = emailTC.text.trim();
    final phone = phoneTC.text.trim();
    final password = passwordTC.text.trim();
    final confirmPassword = confirmPasswordTC.text.trim();

    if (password.isNotEmpty && password != confirmPassword) {
      showSnackbar(context, "Password dan konfirmasi password tidak sama", isError: true);
      return;
    }

    final emailChanged = email.isNotEmpty && email != originalEmail;
    final phoneChanged = phone.isNotEmpty && phone != originalPhone;
    final passwordChanged = password.isNotEmpty;
    final photoChanged = _selectedPhoto != null;

    if (!emailChanged && !phoneChanged && !passwordChanged && !photoChanged) {
      showSnackbar(context, "Tidak ada perubahan data", isError: false);
      return;
    }

    context.read<AuthBloc>().add(UpdateProfileEvent(
      email: emailChanged ? email : null,
      phoneNumber: phoneChanged ? phone : null,
      password: passwordChanged ? password : null,
      passwordConfirmation: passwordChanged ? confirmPassword : null,
      photoPath: kIsWeb ? null : _selectedPhoto?.path,
      photoBytes: _selectedPhotoBytes,
      photoFilename: _selectedPhoto?.name,
    ));
  }

  Future<bool> _showPasswordConfirmDialog() async {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is! ProfileLoaded) return false;

    final username = profileState.profile.username;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BiometricPasswordDialog(username: username),
    );

    if (password != null && mounted) {
      context.read<AuthBloc>().add(
        SaveCredentialsForBiometricEvent(username, password),
      );
      return true;
    }
    return false;
  }


  @override
  void dispose() {
    emailTC.dispose();
    phoneTC.dispose();
    passwordTC.dispose();
    confirmPasswordTC.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is BiometricEnabledLoaded) {
          setState(() => _biometricEnabled = state.enabled);
        } else if (state is AuthLoading) {
          showSnackbar(context, "Menyimpan...", isError: false);
        } else if (state is AuthSuccess) {
          passwordTC.clear();
          confirmPasswordTC.clear();
          setState(() { _selectedPhoto = null; _selectedPhotoBytes = null; });
          showSnackbar(context, state.message, isError: false);
          context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true));
        } else if (state is AuthFailure) {
          showSnackbar(context, state.error, isError: true);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              customHeader(context, "My Profile", isBack: true, colorBack: Color(primaryColor), onBack: () {
                AnalyticsService.logEvent('profile_back');
                context.go('/');
              }),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBody() {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          emailTC.text = state.profile.email;
          phoneTC.text = state.profile.phoneNumber;
        } else if (state is ProfileFailure) {
          // debugPrint('ProfileFailure: ${state.message}');
        }
      },
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
              context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true, silent: true));
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
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            children: [
                              ClipOval(
                                child: _selectedPhotoBytes != null
                                    ? Image.memory(
                                        _selectedPhotoBytes!,
                                        width: 60, height: 60, fit: BoxFit.cover,
                                      )
                                    : user.photoUrl != null
                                        ? Image.network(
                                            user.photoUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => CircleAvatar(
                                              radius: 27,
                                              backgroundColor: Color(primaryColor),
                                              child: Icon(Icons.person, color: Color(whiteColor), size: 37),
                                            ),
                                          )
                                        : CircleAvatar(
                                            radius: 27,
                                            backgroundColor: Color(primaryColor),
                                            child: Icon(Icons.person, color: Color(whiteColor), size: 37),
                                          ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Color(primaryColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Color(whiteColor), width: 1.5),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Color(whiteColor), size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            if (user.userRoleId == 3 || user.salesPersonId != null) ...[
                              if (user.positionName != null && user.positionName!.isNotEmpty)
                                Text(user.positionName!, style: const TextStyle(fontSize: 14, color: Color(blueAccentColor))),
                                if (user.salesTeamName != null && user.salesTeamName!.isNotEmpty)
                                Text(user.salesTeamName!, style: const TextStyle(fontSize: 14, color: Color(blueAccentColor))),
                            ] else ...[
                              if (user.userRoleName != null && user.userRoleName!.isNotEmpty)
                                Text(user.userRoleName!, style: const TextStyle(fontSize: 14, color: Color(blueAccentColor))),
                            ],
                          ],
                        ),
                      ],
                    ),
                    // if (user.nikNumber != null) ...[
                    //   const SizedBox(height: 8),
                    //   Row(
                    //     children: [
                    //       Text(
                    //         "NIK: ${user.nikNumber}",
                    //         style: TextStyle(fontSize: 13, color: Color(greyShade600)),
                    //       ),
                    //     ],
                    //   ),
                    // ],
                    const SizedBox(height: 16),
                    Divider(color: Color(greyShade300)),
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
                          AnalyticsService.logEvent('profile_toggle_password_visibility');
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
                          AnalyticsService.logEvent('profile_toggle_confirm_password_visibility');
                          setState(() {
                            _isObscureConfirm = !_isObscureConfirm;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!kIsWeb) ...[
                    Divider(color: Color(greyShade300)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _biometricEnabled
                                ? Color(primaryColor).withValues(alpha: 0.1)
                                : Color(greyShade100),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _biometricIcon,
                            color: _biometricEnabled ? Color(primaryColor) : Color(greyShade500),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Login Biometrik",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(grey2Color),
                                ),
                              ),
                              Text(
                                _biometricSubtitle,
                                style: TextStyle(fontSize: 12, color: Color(greyShade500)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: _onBiometricToggle,
                          activeThumbColor: Color(primaryColor),
                          activeTrackColor: Color(primaryColor).withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ], // end if (!kIsWeb)
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
                        Expanded(child: customButton(() => _submit(user.email, user.phoneNumber), "Submit")),
                        const SizedBox(width: 20),
                        Expanded(
                          child: customButton(
                            () => _showLogoutConfirmation(),
                            "Logout",
                            colorBg: Color(whiteColor),
                            colorText: Color(primaryColor),
                          ),
                        ),
                      ],
                    ),
                    // Superadmin: login sebagai user lain (impersonate) untuk uji permission.
                    if (PermissionsHelper.isSuperadmin) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AnalyticsService.logEvent('profile_login_as_user');
                            context.push('/impersonate');
                          },
                          icon: const Icon(Icons.people_alt_outlined, size: 18),
                          label: const Text('Login Sebagai User'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(primaryColor),
                            side: BorderSide(color: Color(primaryColor)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () {
                    //       context.read<AuthBloc>().add(FetchPermissionsEvent());
                    //       showSnackbar(context, 'Permissions dicetak di debug console', isError: false);
                    //     },
                    //     icon: const Icon(Icons.terminal, size: 16),
                    //     label: const Text('Print Permissions'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Color(primaryColor),
                    //       side: BorderSide(color: Color(primaryColor)),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () async {
                    //       final prefs = await SharedPreferences.getInstance();
                    //       final stored = prefs.getString('auth_token');
                    //       final token = ProxyCipher.decryptString(stored) ?? '-';
                    //       debugPrint('[TOKEN] $token');
                    //       await Clipboard.setData(ClipboardData(text: token));
                    //       if (context.mounted) showSnackbar(context, 'Token disalin ke clipboard', isError: false);
                    //     },
                    //     icon: const Icon(Icons.copy, size: 16),
                    //     label: const Text('Print Token'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Color(primaryColor),
                    //       side: BorderSide(color: Color(primaryColor)),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //     ),
                    //   ),
                    // ),
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
  //         Text(node.positionName!, style: TextStyle(color: Color(greyShade600), fontSize: 12)),
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
  //       data: Theme.of(context).copyWith(dividerColor: Color(transparentColor)),
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
  //         Text(node.positionName!, style: TextStyle(color: Color(greyShade600), fontSize: 12)),
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
  //       data: Theme.of(context).copyWith(dividerColor: Color(transparentColor)),
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
      height: 60,
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
          fillColor: Color(greyShade50),
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

class _BiometricPasswordDialog extends StatefulWidget {
  final String username;
  const _BiometricPasswordDialog({required this.username});

  @override
  State<_BiometricPasswordDialog> createState() => _BiometricPasswordDialogState();
}

class _BiometricPasswordDialogState extends State<_BiometricPasswordDialog> {
  final _passController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Konfirmasi Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Masukkan password untuk akun",
            style: TextStyle(fontSize: 13, color: Color(greyShade600)),
          ),
          Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _passController,
            obscureText: _isObscure,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Password",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            final pass = _passController.text.trim();
            if (pass.isEmpty) return;
            Navigator.of(context).pop(pass);
          },
          child: const Text("Aktifkan"),
        ),
      ],
    );
  }

}