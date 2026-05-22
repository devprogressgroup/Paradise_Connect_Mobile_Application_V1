import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

class CustomFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback? onClear;

  const CustomFilterButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Color(primaryColor) : Color(whiteColor),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Color(primaryColor) : Colors.transparent,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Color(blackColor),
                ),
              ),
              const SizedBox(width: 4),
              if (isSelected && onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isSelected ? Colors.white : Color(blackColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
