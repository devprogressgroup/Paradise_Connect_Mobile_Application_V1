
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


Widget customHeader(BuildContext context, String title, {bool isBack = false, Color? colorBack, Color? colorBg, Color? colorTitle,IconData? iconLeft, IconData? iconRight,VoidCallback? iconLeftOnTap,VoidCallback? iconRightOnTap, VoidCallback? onBack, Color? colorIconLeft, Color? colorIconRight}) {
  return Container(
    decoration: BoxDecoration(
      color: colorBg ?? Colors.white,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal:iconRight != null?13: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTitle)),
            ],
          ),
          if(iconLeft != null)
          IconButton(
          icon:  Icon(iconLeft, size: 24, color: colorIconLeft),
          onPressed: () {
            iconLeftOnTap?.call();
          },
        ),
        ],
      ),
    ),
  );
}
