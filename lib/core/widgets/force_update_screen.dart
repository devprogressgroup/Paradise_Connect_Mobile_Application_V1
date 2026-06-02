import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(logoParadiseConnect, width: 120),
                const SizedBox(height: 40),
                const Icon(Icons.system_update_rounded, size: 64, color: Color(0xFF1565C0)),
                const SizedBox(height: 24),
                const Text(
                  'Pembaruan Diperlukan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tersedia versi terbaru aplikasi Paradise Connect. Harap perbarui aplikasi untuk melanjutkan.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VersionBadge(
                        label: 'Versi Kamu',
                        version: currentVersion,
                        color: Colors.red[400]!,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      const SizedBox(width: 16),
                      _VersionBadge(
                        label: 'Versi Terbaru',
                        version: latestVersion,
                        color: Colors.green[600]!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: downloadUrl.isNotEmpty
                        ? () async {
                            final uri = Uri.parse(downloadUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Sekarang', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final String version;
  final Color color;

  const _VersionBadge({required this.label, required this.version, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
