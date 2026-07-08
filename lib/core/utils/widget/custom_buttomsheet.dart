import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

void showCustomBottomSheet({ required BuildContext context, required Widget child,}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Color(transparentColor),
    builder: (context) {
      return Container(
        child: Container(
          width: double.infinity, 
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Color(grey7Color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      );
    },
  );
}