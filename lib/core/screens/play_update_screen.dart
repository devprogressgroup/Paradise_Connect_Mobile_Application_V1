import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/services/play_update_service.dart';

/// Layar wajib update untuk app yang di-install dari Google Play. Proses download & install
/// diurus layar full-screen milik Play (immediate update); layar ini hanya jadi penghalang
/// supaya app tidak bisa dipakai kalau user membatalkan atau update gagal dimulai.
class PlayUpdateScreen extends StatefulWidget {
  const PlayUpdateScreen({super.key});

  @override
  State<PlayUpdateScreen> createState() => _PlayUpdateScreenState();
}

class _PlayUpdateScreenState extends State<PlayUpdateScreen> {
  bool _busy = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('play_update_screen');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startUpdate());
  }

  Future<void> _startUpdate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMsg = '';
    });

    final result = await PlayUpdateService.startImmediateUpdate();
    if (!mounted) return;

    setState(() {
      _busy = false;
      switch (result) {
        case AppUpdateResult.success:
          _errorMsg = '';
        case AppUpdateResult.userDeniedUpdate:
          _errorMsg = 'Update dibatalkan. Aplikasi harus diperbarui untuk melanjutkan.';
        case AppUpdateResult.inAppUpdateFailed:
          _errorMsg = 'Update gagal dimulai. Coba lagi, atau perbarui lewat Google Play.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(whiteColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(logoSplasShcreen, width: 180),
              const Spacer(flex: 1),
              const Text(
                'Pembaruan Wajib',
                style: TextStyle(
                  color: Color(blackColor),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Versi baru tersedia di Google Play. Perbarui aplikasi untuk melanjutkan.',
                style: TextStyle(color: Color(grey2Color), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (_errorMsg.isNotEmpty) ...[
                const Icon(Icons.error_outline, color: Color(redColor), size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMsg,
                  style: const TextStyle(color: Color(grey2Color), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          AnalyticsService.logEvent('play_update_screen_retry');
                          _startUpdate();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(primaryColor),
                    foregroundColor: const Color(whiteColor),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(whiteColor),
                          ),
                        )
                      : const Text(
                          'Update Sekarang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('play_update_screen_open_store');
                    PlayUpdateService.openStoreListing();
                  },
                  icon: const Icon(Icons.shop_rounded, color: Color(primaryColor)),
                  label: const Text(
                    'Buka Google Play',
                    style: TextStyle(color: Color(primaryColor), fontSize: 15),
                  ),
                ),
              ],

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
