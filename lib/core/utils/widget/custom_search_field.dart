import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';

Widget customSearchField({required TextEditingController controller,required FocusNode focusNode,String hintText = 'Search',String? iconPath}) {
  return Container(
    height: 40,
    child: TextFormField(
      controller: controller,
      focusNode: focusNode,
      onTapOutside: (event) => focusNode.unfocus(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Color(grey3Color)),
        filled: true,
        fillColor: Color(whiteColor),
        prefixIcon: Image.asset(icNavSearch),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(grey4Color),width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(primaryColor),width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Color(redPeriodColor),width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide(color: Colors.grey,width: 1)),
      ),
    ),
  );
}