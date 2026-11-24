import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka tautan di luar aplikasi (browser atau aplikasi lain) hanya setelah pengguna mengonfirmasi.
Future<void> openExternalFeedLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Buka di luar aplikasi?'),
      content: Text(
        'Tautan ini akan dibuka di browser atau aplikasi lain'
       
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Buka'),
        ),
      ],
    ),
  );
  if (proceed != true) return;

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
