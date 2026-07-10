import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/widget/floating_download_overlay.dart';

Future<void> showGlobalNotificationDialog(
  BuildContext context, {
  required String title,
  required String description,
  String? mediaType,
  String? mediaUrl,
}) {
  final hasImage = mediaType == 'image' && (mediaUrl?.isNotEmpty ?? false);
  final hasPdf = mediaType == 'pdf' && (mediaUrl?.isNotEmpty ?? false);

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (description.isNotEmpty) Text(description),
            if (hasPdf) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  FloatingDownloadManager.show(
                    context: context,
                    url: mediaUrl!,
                    filename: '$title.pdf',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Lihat Dokumen'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK, Paham'),
        ),
      ],
    ),
  );
}
