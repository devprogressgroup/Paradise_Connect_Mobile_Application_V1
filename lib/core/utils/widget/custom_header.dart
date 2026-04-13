
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/assets.dart';

Widget customHeader(BuildContext context, String title, {bool isBack = false, Color? colorBack, Color? colorBg, Color? colorTitle, bool isHome = false}) {
  return Container(
    color: colorBg ?? Colors.white,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: isHome ? headerHome(context) : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              !isBack ? SizedBox(): Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: Icon(Icons.arrow_back, size: 27, color: colorBack),
                  ),
                  SizedBox(width: 10),
                ],
              ),
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTitle))),
            ],
          ),
        ],
      ),
    ),
  );
}


Widget headerHome (BuildContext context){
  return Container(
    height: 35,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Row(
            children: [
              Image.asset(icHomeDashboard, width: 20, height: 20),
              const SizedBox(width: 8),
              Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 24),
          onPressed: () {
            context.pushNamed('notif');
          },
        ),
      ],
    ),
  );
}