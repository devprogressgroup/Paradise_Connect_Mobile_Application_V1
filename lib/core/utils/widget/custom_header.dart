
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


Widget customHeader(BuildContext context, String title, {bool isBack = false, Color? colorBack, Color? colorBg, Color? colorTitle,IconData? iconLeft, IconData? iconRight,VoidCallback? iconLeftOnTap,VoidCallback? iconRightOnTap, VoidCallback? onBack, Color? colorIconLeft, Color? colorIconRight, bool showBadgeLeft = false, IconData? iconLeft2, Color? colorIconLeft2, VoidCallback? iconLeft2OnTap}) {
  return Container(
    decoration: BoxDecoration(
      color: colorBg ?? Colors.white,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal:iconRight != null?13: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if(iconRight != null)
                Container(
                  width: 40,
                  child: IconButton(
                    icon:  Icon(iconRight, size: 24, color: colorBack),
                    onPressed: () {
                      iconRightOnTap?.call();
                    },
                  ),
                ),
                !isBack ? SizedBox(): Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (onBack != null) {
                          onBack();
                        } else {
                          context.pop();
                        }
                      },
                      child: Icon(Icons.arrow_back, size: 27, color: colorBack),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTitle))),
              ],
            ),
          ),
          if(iconLeft2 != null)
                IconButton(
                  icon: Icon(iconLeft2, size: 24, color: colorIconLeft2),
                  onPressed: () {
                    iconLeft2OnTap?.call();
                  },
                ),
          if (iconLeft != null || iconLeft2 != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(iconLeft2 != null)
                IconButton(
                  icon: Icon(iconLeft2, size: 24, color: colorIconLeft2),
                  onPressed: () {
                    iconLeft2OnTap?.call();
                  },
                ),
              if(iconLeft != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon:  Icon(iconLeft, size: 24, color: colorIconLeft),
                    onPressed: () {
                      iconLeftOnTap?.call();
                    },
                  ),
                  if (showBadgeLeft)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
