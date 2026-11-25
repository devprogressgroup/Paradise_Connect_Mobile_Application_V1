import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_report/feed_report_cubit.dart';

/// Tombol "Laporkan" untuk kartu kiriman di Home. Hanya muncul untuk kiriman tayang milik orang lain.
class FeedReportButton extends StatelessWidget {
  final FeedPostEntity post;

  const FeedReportButton({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showReportPostDialog(context, post),
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Laporkan'),
      ),
    );
  }
}

/// Pilih alasan dan catatan opsional, lalu kirim laporan. Approver diberi tahu lewat notifikasi di server.
Future<void> showReportPostDialog(BuildContext context, FeedPostEntity post) async {
  AnalyticsService.logEvent('marketing_feed_report');
  var reason = FeedReportReason.spam.code;
  final noteController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Laporkan kiriman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in FeedReportReason.values)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.label),
                trailing: Icon(
                  reason == r.code ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: const Color(primaryColor),
                  size: 20,
                ),
                onTap: () => setDialogState(() => reason = r.code),
              ),
            TextField(
              controller: noteController,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Catatan (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
        ],
      ),
    ),
  );
  final note = noteController.text.trim();
  noteController.dispose();
  if (confirmed != true || !context.mounted) return;

  final error = await context.read<FeedReportCubit>().report(
    post.id,
    reason,
    note.isEmpty ? null : note,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Laporan terkirim. Tim akan meninjau kiriman ini.')),
  );
}
