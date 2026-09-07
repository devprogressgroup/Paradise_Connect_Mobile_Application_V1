import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class UnitStatusBadge extends StatelessWidget {
  final String label;

  /// Warna teks. Default putih (perilaku lama). Status "Available"/"Reserve" memakai warna latar
  /// yang sangat terang (#00FF0C / #EAFF00) sehingga teks putih hampir tidak terbaca — pemanggil
  /// yang menampilkan badge di atas latar terang bisa mengirim warna gelap. Sengaja opsional
  /// supaya tampilan layar lain yang sudah ada tidak berubah.
  final Color? textColor;

  const UnitStatusBadge({super.key, required this.label, this.textColor});

  Color get _bgColor {
    switch (label.trim().toLowerCase()) {
      case 'available':
        return const Color(availableColor);
      case 'hold':
        return const Color(holdColor);
      case 'rba':
        return const Color(rbaColor);
      case 'rbb':
        return const Color(rbbColor);
      case 'reserve':
        return const Color(reserveColor);
      case 'sp':
        return const Color(spColor);
      default:
        return const Color(greyShade500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor ?? const Color(whiteColor), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
