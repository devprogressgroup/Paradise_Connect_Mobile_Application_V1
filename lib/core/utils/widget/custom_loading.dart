import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// [message] opsional — tampil di bawah spinner (mis. "Menghapus…") supaya user tahu proses apa
/// yang sedang jalan. Tombol back dikunci: loading cuma boleh ditutup lewat [hideLoadingDialog].
void showLoadingDialog(
  bool loadingDialogShown,
  BuildContext context, {
  String? message,
}) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Center(
        child: message == null
            ? const CircularProgressIndicator()
            : Material(
                color: const Color(whiteColor),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(grey1Color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}

void hideLoadingDialog(bool loadingDialogShown, BuildContext context) {
  if (!context.mounted) return;
  try {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  } catch (_) {}
}
