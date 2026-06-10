import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

void showSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Color(redColor) : Color(greenPercentColor),
    ),
  );
}