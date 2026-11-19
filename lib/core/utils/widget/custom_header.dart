import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';

Widget customHeader(
  BuildContext context,
  String title, {
  bool isBack = false,
  Color? colorBack,
  Color? colorBg,
  Color? colorTitle,
  IconData? iconLeft,
  IconData? iconRight,
  VoidCallback? iconLeftOnTap,
  VoidCallback? iconRightOnTap,
  VoidCallback? onBack,
  Color? colorIconLeft,
  Color? colorIconRight,
  bool showBadgeLeft = false,
  IconData? iconLeft2,
  Color? colorIconLeft2,
  VoidCallback? iconLeft2OnTap,
  Widget? trailing,
  /// Ikon tambahan di antara ikon search dan lonceng (mis. Kalender Jadwal untuk moderator).
  List<Widget> extraActions = const [],
}) {
  return Container(
    decoration: BoxDecoration(color: colorBg ?? Color(whiteColor)),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: iconRight != null ? 13 : 20,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              children: [
                if (iconRight != null)
                  Container(
                    width: 34,
                    child: IconButton(
                      icon: Icon(iconRight, size: 20, color: colorBack),
                      padding: const EdgeInsets.all(1),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        iconRightOnTap?.call();
                      },
                    ),
                  ),
                !isBack
                    ? SizedBox()
                    : Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (onBack != null) {
                                onBack();
                              } else {
                                context.pop();
                              }
                            },
                            child: Icon(
                              Icons.arrow_back,
                              size: 27,
                              color: colorBack,
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (iconLeft != null || trailing != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (iconLeft2 != null)
                  Container(
                    width: 20,
                    child: IconButton(
                      icon: Icon(iconLeft2, size: 20, color: colorIconLeft2),
                      padding: const EdgeInsets.all(1),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        iconLeft2OnTap?.call();
                      },
                    ),
                  ),
                ...extraActions,
                if (iconLeft != null) Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                    width: 20,
                      child: IconButton(
                        icon: Icon(iconLeft, size: 25, color: colorIconLeft),
                        padding: const EdgeInsets.all(1),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          iconLeftOnTap?.call();
                        },
                      ),
                    ),
                    if (showBadgeLeft)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Color(redAccentColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
        ],
      ),
    ),
  );
}
