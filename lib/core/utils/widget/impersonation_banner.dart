import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/impersonation_manager.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';

/// Banner global "sedang impersonate" — tampil di semua halaman shell saat
/// superadmin sedang login-as user lain. Berisi nama target + tombol "Keluar".
class ImpersonationBanner extends StatelessWidget {
  const ImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ImpersonationManager.nameNotifier,
      builder: (context, name, _) {
        if (name == null) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFFEA580C), // oranye mencolok
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sedang sebagai: $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<AuthBloc>().add(StopImpersonationEvent()),
                    icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                    label: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
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
