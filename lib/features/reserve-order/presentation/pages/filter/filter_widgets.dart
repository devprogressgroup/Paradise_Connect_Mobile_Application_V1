import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Potongan visual bersama untuk bottom sheet ala Contacts (`ContactFilterSheet`) yang dipakai
/// baik oleh sheet filter status ([filter_sheet.dart]) maupun sheet urutkan ([sort_sheet.dart]) —
/// keduanya sheet terpisah (tombol pemicu masing-masing sendiri), tapi bahasa visualnya sama:
/// drag handle, kartu section rounded dengan header ikon+judul, dan baris opsi radio.
Widget reserveFilterSheetHandle() {
  return Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 6),
    decoration: BoxDecoration(color: const Color(grey7Color), borderRadius: BorderRadius.circular(2)),
  );
}

Widget reserveFilterSectionCard({required IconData icon, required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(whiteColor),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(grey10Color)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Icon(icon, size: 14, color: const Color(primaryColor)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(grey5Color)),
              ),
            ],
          ),
        ),
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(grey10Color)),
          children[i],
        ],
      ],
    ),
  );
}

Widget reserveFilterOptionRow(String label, {required bool selected, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      color: selected ? const Color(primaryColor).withValues(alpha: 0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: selected ? const Color(primaryColor) : const Color(grey7Color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(blue2Color) : const Color(grey1Color),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
