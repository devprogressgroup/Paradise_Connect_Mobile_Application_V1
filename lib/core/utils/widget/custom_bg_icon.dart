

import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class BgIcon extends StatelessWidget {
  final String? asset;
  final VoidCallback? onTap;
  final IconData fallbackIcon;
  final Color? color;

  const BgIcon({
    super.key,
    this.asset,
    this.onTap,
    this.fallbackIcon = Icons.more_vert,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(grey8Color),
            borderRadius: BorderRadius.circular(14),
          ),
          child: asset != null && asset!.isNotEmpty
              ? Image.asset(
                  asset!,
                  width: 35,
                  height: 35,
                  errorBuilder: (_, __, ___) => Icon(fallbackIcon),
                  color: color,
                )
              : Icon(fallbackIcon, size: 35,),
        ),
      ),
    );
  }
}