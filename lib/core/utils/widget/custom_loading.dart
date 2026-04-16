
  import 'package:flutter/material.dart';

void showLoadingDialog(bool loadingDialogShown, BuildContext context) {
    if (loadingDialogShown) return;
    loadingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoadingDialog(bool loadingDialogShown, BuildContext context) {
    if (!loadingDialogShown) return;
    loadingDialogShown = false;
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
  }
