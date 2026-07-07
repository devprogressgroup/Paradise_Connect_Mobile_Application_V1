import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Banner "update tersedia" — mirip [ImpersonationBanner], nempel di atas
class UpdateBanner extends StatelessWidget {
  static const String downloadLink = 'lp.connect.paradise.id';

  const UpdateBanner({super.key});

  void _copyLink(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: downloadLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link disalin: $downloadLink'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDC2626), 
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.system_update_alt, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Versi baru tersedia. Silakan uninstall aplikasi Anda, lalu download ulang di link:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _copyLink(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            downloadLink,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
