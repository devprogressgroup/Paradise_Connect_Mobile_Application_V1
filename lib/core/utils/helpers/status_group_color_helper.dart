import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

Color statusGroupColor(String group) {
  switch (group) {
    case 'lost':
      return Color(redColor);
    case 'appt':
      return Color(primaryColor);
    case 'visitor':
      return Color(warningColor);
    case 'reserve':
      return Color(lightGreenColor);
    case 'sp':
      return Color(darkGreenColor);
    case 'db':
    default:
      return Color(purpleColor);
  }
}
