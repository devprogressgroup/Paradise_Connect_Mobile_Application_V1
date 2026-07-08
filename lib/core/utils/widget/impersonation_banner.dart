import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/impersonation_manager.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/core/constants/colors.dart';

class ImpersonationBanner extends StatelessWidget {
  const ImpersonationBanner({super.key});

  void _confirmStopImpersonation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Impersonate?'),
        content: const Text('Kamu akan kembali ke akun admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(StopImpersonationEvent());
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ImpersonationManager.nameNotifier,
      builder: (context, name, _) {
        if (name == null) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFFEA580C),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Color(whiteColor), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sedang sebagai: $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(whiteColor),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmStopImpersonation(context),
                    icon: const Icon(Icons.logout, color: Color(whiteColor), size: 16),
                    label: const Text('Keluar', style: TextStyle(color: Color(whiteColor), fontWeight: FontWeight.bold)),
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
