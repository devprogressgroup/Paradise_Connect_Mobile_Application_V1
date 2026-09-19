import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Banner "Ditolak" merah — dipakai di halaman Reserve Order (Detail, Edit Customer,
/// Top Up/Resubmit) untuk menampilkan alasan penolakan yang perlu direvisi Sales.
class RejectBanner extends StatelessWidget {
  final String title;
  final String reason;

  const RejectBanner({super.key, required this.title, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              const Icon(Icons.cancel, size: 15, color: Color(redColor)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(redColor))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reason, style: const TextStyle(fontSize: 11, color: Color(roRejectTextColor), height: 1.4)),
        ],
      ),
    );
  }
}
