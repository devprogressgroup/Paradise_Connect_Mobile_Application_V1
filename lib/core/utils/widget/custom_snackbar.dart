import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Snackbar konsisten: sukses = hijau, gagal ([isError]) = merah, terkunci ([isLocked]) = abu-abu + gembok.
void showSnackbar(
  BuildContext context,
  String message, {
  bool isError = false,
  /// Alasan kunci (aksi tidak bisa dilakukan karena status data) — abu-abu dgn ikon gembok.
  bool isLocked = false,
  /// null = durasi default SnackBar (4 detik). Isi lebih lama utk pesan panjang.
  Duration? duration,
}) {
  final color = isError
      ? const Color(redColor)
      : isLocked
      ? const Color(grey2Color)
      : const Color(greenPercentColor);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: isLocked
          ? Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            )
          : Text(message),
      backgroundColor: color,
      duration: duration ?? const Duration(milliseconds: 4000),
    ),
  );
}
