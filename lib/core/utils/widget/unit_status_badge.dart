import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class UnitStatusBadge extends StatelessWidget {
  final String label;

  const UnitStatusBadge({super.key, required this.label});

  Color get _bgColor {
    switch (label.trim().toLowerCase()) {
      case 'available':
        return const Color(successColor);
      case 'hold':
        return const Color(redColor);
      case 'rbb':
        return const Color(orangeAccentColor);
      case 'reserve':
        return const Color(amberMaterialColor);
      case 'sp':
        return const Color(blueShade900Color);
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
        style: const TextStyle(color: Color(whiteColor), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
