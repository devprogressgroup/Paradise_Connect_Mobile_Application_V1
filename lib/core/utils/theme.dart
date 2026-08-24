import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(primaryColor),
      surface: Color(backgroundColor),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Color(backgroundColor),
      textTheme: _buildTextTheme(brightness),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    return GoogleFonts.nunitoSansTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );
  }
}

// Default MaterialScrollBehavior tidak menganggap mouse sebagai `dragDevices` (klik-tahan-geser
// dengan mouse diasumsikan buat text selection, bukan scroll/drag) — di PWA (web desktop,
// ditest pakai mouse) ini bikin DraggableScrollableSheet (mis. bottom sheet Unit Detail)
// tidak bisa ditarik naik sampai maxChildSize, karena drag gesture-nya memang tidak pernah
// terdaftar. Mobile tidak kena (touch sudah termasuk default dragDevices).
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}
