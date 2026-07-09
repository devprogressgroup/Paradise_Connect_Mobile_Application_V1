import 'package:flutter/material.dart';

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
    builder: (ctx) => AlertDialog(
      title: Text(isOk ? '✅ Feedback Absensi: Sesuai' : '⚠️ Feedback Absensi: Perlu Perbaikan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  height: 160,
                  width: double.infinity,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onAcknowledge();
          },
          child: const Text('OK, Paham'),
        ),
      ],
    ),
  );
}
