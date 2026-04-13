import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

Widget customButton (VoidCallback onTap, String title){
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(whiteColor)))),
      ),
    );
  }
