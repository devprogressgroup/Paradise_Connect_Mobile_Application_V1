import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';


const Color roIconBg = Color(roIconBgColor);
const Color roSelectedBg = Color(roSelectedBgColor);

Widget roAppBar({
  required String title,
  String? subtitle,
  String? avatarInitials,
  required VoidCallback onBack,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    decoration: BoxDecoration(
      color: const Color(whiteColor),
      border: Border(bottom: BorderSide(color: const Color(grey10Color))),
    ),
    child: Row(
      children: [
        InkWell(
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(grey1Color)),
          ),
        ),
        if (avatarInitials != null) ...[
          roAvatar(avatarInitials, size: 34),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(blue2Color)),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Color(grey4Color)),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget roAvatar(String initials, {double size = 40, Color? color, Color? textColor}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color ?? roIconBg, shape: BoxShape.circle),
    child: Text(
      initials,
      style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: textColor ?? const Color(roAvatarTextColor)),
    ),
  );
}

Widget roStatusBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(whiteColor)),
    ),
  );
}

Widget roFieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(grey1Color)),
    ),
  );
}

Widget roSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Color(grey4Color))),
  );
}

Widget roInput(
  TextEditingController controller, {
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  int maxLines = 1,
  bool hasError = false,
  ValueChanged<String>? onChanged,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide(color: Color(hasError ? redColor : grey7Color)),
  );

  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 12.5, color: Color(blue2Color)),
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(grey11Color),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(grey5Color)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: Color(hasError ? redColor : primaryColor)),
      ),
    ),
  );
}

Widget roPrimaryButton(String text, VoidCallback? onTap, {bool loading = false}) {
  final enabled = onTap != null && !loading;

  return InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(enabled ? primaryColor : grey7Color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(enabled ? primaryColor : grey7Color)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(whiteColor)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(whiteColor)),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget roGhostButton(String text, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(11),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(primaryColor), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(primaryColor)),
      ),
    ),
  );
}

Widget roChip(String text, bool selected, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(selected ? primaryColor : whiteColor),
        border: Border.all(color: Color(selected ? primaryColor : grey7Color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(selected ? whiteColor : grey1Color),
        ),
      ),
    ),
  );
}

Widget roDocTile(ReserveOrderDoc doc, {VoidCallback? onTap}) {
  final (Color border, Color iconBg, Color iconColor, Color statusColor) = switch (doc.state) {
    ReserveOrderDocState.awaitingUpload => (const Color(grey10Color), roIconBg, const Color(primaryColor), const Color(primaryColor)),
    ReserveOrderDocState.uploaded => (const Color(grey10Color), roIconBg, const Color(primaryColor), const Color(grey4Color)),
    ReserveOrderDocState.pending => (const Color(warningColor), const Color(roAmberBgColor), const Color(warningColor), const Color(warningColor)),
    ReserveOrderDocState.rejected => (const Color(redColor), const Color(roLightRedBgColor), const Color(redColor), const Color(redColor)),
    ReserveOrderDocState.issued => (const Color(spColor), const Color(roLightPurpleBgColor), const Color(spColor), const Color(grey4Color)),
  };

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(doc.icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: doc.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                    children: [
                      if (doc.badge != null)
                        TextSpan(
                          text: ' ${doc.badge}',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w400, color: Color(grey4Color)),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(doc.status, style: TextStyle(fontSize: 10, color: statusColor)),
              ],
            ),
          ),
          if (doc.state == ReserveOrderDocState.uploaded)
            const Icon(Icons.check, size: 16, color: Color(successColor)),
        ],
      ),
    ),
  );
}

Widget roRejectBanner(String reason) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(roLightRedBgColor),
      border: Border.all(color: const Color(roRejectBorderColor)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.close_rounded, size: 15, color: Color(redColor)),
            const SizedBox(width: 4),
            const Text(
              'Rejected — Needs Revision',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(redColor)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(reason, style: const TextStyle(fontSize: 11, height: 1.5, color: Color(roRejectTextColor))),
      ],
    ),
  );
}

Widget roSummaryLine(String label, String value, {bool isLast = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      border: isLast ? null : Border(bottom: BorderSide(color: const Color(grey10Color))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(grey1Color))),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
        ),
      ],
    ),
  );
}

Widget roFooter(List<Widget> children) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
    decoration: BoxDecoration(
      color: const Color(whiteColor),
      border: Border(top: BorderSide(color: const Color(grey10Color))),
    ),
    child: Column(children: children),
  );
}

/// Baris tappable buat field pilihan (Marital Status, Payment Plan, dll) — dipasangkan dengan
/// [roShowOptionSheet]. Dipakai bareng oleh form Reserve & halaman Edit Customer.
Widget roPickerRow({required String? value, required String hint, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(grey10Color), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 12.5,
                color: value == null ? const Color(grey5Color) : const Color(blue2Color),
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 22, color: Color(grey4Color)),
        ],
      ),
    ),
  );
}

/// Sheet pilihan teks polos buat [roPickerRow] — daftar [items], centang di [selected].
void roShowOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String? selected,
  required ValueChanged<String> onPicked,
}) {
  showCustomBottomSheet(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(blue2Color)),
          ),
        ),
        for (final item in items)
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onPicked(item);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13, color: Color(blue2Color))),
                  ),
                  if (item == selected) const Icon(Icons.check, size: 18, color: Color(primaryColor)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Header section yang bisa expand/collapse (garis bawah + panah yang berputar 180° saat kebuka)
/// — dipakai `ReserveOrderEditCustomerPage` & tab "Customer" di `ReserveOrderDetailPage` supaya
/// gaya & interaksinya konsisten di kedua halaman.
Widget roCollapsibleSectionHeader({required String title, required bool collapsed, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(primaryColor).withValues(alpha: 0.35), width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(blue2Color)),
            ),
          ),
          AnimatedRotation(
            turns: collapsed ? 0 : 0.5,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(primaryColor)),
          ),
        ],
      ),
    ),
  );
}
