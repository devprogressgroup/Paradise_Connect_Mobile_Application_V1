import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';

Future<void> showAttendanceFeedbackDialog(
  BuildContext context, {
  required bool isOk,
  required List<String> categoryLabels,
  required String note,
  required String photoUrl,
  required VoidCallback onAcknowledge,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOk ? '✅ Feedback Absensi: Sesuai' : '⚠️ Feedback Absensi: Perlu Perbaikan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                if (photoUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      height: 160,
                      width: double.maxFinite,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (categoryLabels.isNotEmpty) ...[
                  const Text('Catatan masalah:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...categoryLabels.map((c) => Text('• $c')),
                  const SizedBox(height: 8),
                ],
                if (note.isNotEmpty) Text(note),
                const SizedBox(height: 20),
                customButton(
                  () {
                    Navigator.of(ctx).pop();
                    onAcknowledge();
                  },
                  'OK, Paham',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
