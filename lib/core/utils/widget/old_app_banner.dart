import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/old_app_check_service.dart';

/// Banner "aplikasi lama masih terinstall" — mirip [ImpersonationBanner], nempel di atas
class OldAppBanner extends StatelessWidget {
  const OldAppBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OldAppCheckService.detectedNotifier,
      builder: (context, detected, _) {
        if (!detected) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFFDC2626),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(whiteColor), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Aplikasi versi lama masih terinstall',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(whiteColor),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      print("Uninstall");
                      final error = await OldAppCheckService.openUninstallOldApp();

                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuka uninstall: $error')),
                        );
                      }
                      print("Uninstall : $error");
                    },
                    icon: const Icon(Icons.delete_outline, color: Color(whiteColor), size: 16),
                    label: const Text('Uninstall', style: TextStyle(color: Color(whiteColor), fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Color(whiteColor).withValues(alpha: 0.18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
