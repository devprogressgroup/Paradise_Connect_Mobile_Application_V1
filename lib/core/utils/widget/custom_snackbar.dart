import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

void showSnackbar(
  BuildContext context,
  String message, {
  bool isError = false,
  /// null = durasi default SnackBar (4 detik). Isi lebih lama utk pesan panjang.
  Duration? duration,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Color(redColor) : Color(greenPercentColor),
      duration: duration ?? const Duration(milliseconds: 4000),
    ),
  );
}
