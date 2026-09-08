import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';

/// Potongan UI yang dipakai bareng oleh halaman-halaman menu Reserve Order (list, detail, top up,
/// ajukan ulang). Ukuran & warnanya mengikuti mockup `reserve-order-sales-final_12.html` Bagian 3.

const Color roIconBg = Color(0xFFE6F1FB);
const Color roSelectedBg = Color(0xFFE8F2FE);

/// App bar mockup: tombol back, avatar inisial opsional, judul + subjudul kecil.
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

/// Lingkaran inisial pembeli / penulis catatan. Default-nya biru muda ala header mockup; avatar
/// catatan mengirim warna solid per peran + teks putih.
Widget roAvatar(String initials, {double size = 40, Color? color, Color? textColor}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color ?? roIconBg, shape: BoxShape.circle),
    child: Text(
      initials,
      style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: textColor ?? const Color(0xFF0C447C)),
    ),
  );
}

/// Badge tahap transaksi (Diproses / R/BR / SP / …). Label dikirim terpisah dari warnanya karena
/// nama tahap bisa lebih spesifik daripada enum statusnya — lihat `ReserveOrder.badgeLabel`.
Widget roStatusBadge(String label, Color color) {
  // SP & Reserve Booking memakai latar gelap/pekat, teks putih tetap terbaca. Warna RBB (#FEB900)
  // paling terang di antara semuanya tapi masih aman dengan teks putih tebal.
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

/// Tombol utama dengan status loading — dipakai saat mengajukan top up / submit ulang supaya
/// tombolnya tidak bisa ditekan dua kali dan prosesnya kelihatan.
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

/// Baris dokumen di tab Attachment / halaman top up & ajukan ulang. Warna border dan teks status
/// mengikuti [ReserveOrderDocState] — merah untuk yang ditolak, kuning untuk yang masih diverifikasi.
Widget roDocTile(ReserveOrderDoc doc, {VoidCallback? onTap}) {
  final (Color border, Color iconBg, Color iconColor, Color statusColor) = switch (doc.state) {
    ReserveOrderDocState.awaitingUpload => (const Color(grey10Color), roIconBg, const Color(primaryColor), const Color(primaryColor)),
    ReserveOrderDocState.uploaded => (const Color(grey10Color), roIconBg, const Color(primaryColor), const Color(grey4Color)),
    ReserveOrderDocState.pending => (const Color(warningColor), const Color(0xFFFFF6E5), const Color(warningColor), const Color(warningColor)),
    ReserveOrderDocState.rejected => (const Color(redColor), const Color(0xFFFDECEC), const Color(redColor), const Color(redColor)),
    ReserveOrderDocState.issued => (const Color(spColor), const Color(0xFFE9E7FE), const Color(spColor), const Color(grey4Color)),
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

/// Banner merah "Ditolak — Perlu Revisi" beserta alasannya.
Widget roRejectBanner(String reason) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFDECEC),
      border: Border.all(color: const Color(0xFFF6B8B8)),
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
              'Ditolak — Perlu Revisi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(redColor)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(reason, style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF7A1F1F))),
      ],
    ),
  );
}

/// Baris "label ..... nilai" di kartu ringkasan.
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

/// Footer putih dengan garis atas untuk tombol utama.
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
