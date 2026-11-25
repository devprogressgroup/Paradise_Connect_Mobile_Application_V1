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
      child: BlocBuilder<FeedReportCubit, FeedReportState>(
        buildWhen: (a, b) =>
            a.reportedIds.contains(post.id) != b.reportedIds.contains(post.id),
        builder: (context, state) {
          // Sudah dilaporkan: dari server (my_report) atau baru dikirim di sesi ini.
          final reported = post.reportedByMe || state.reportedIds.contains(post.id);
          if (reported) {
            return TextButton.icon(
              onPressed: null,
              icon: Icon(Icons.check, size: 16),
              label: Text('Sudah dilaporkan'),
            );
          }
          return TextButton.icon(
            onPressed: () => showReportPostDialog(context, post),
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('Laporkan'),
          );
        },
      ),
    );
  }
}

/// Pilih alasan dan catatan opsional, lalu kirim laporan. Approver diberi tahu lewat notifikasi di server.
Future<void> showReportPostDialog(BuildContext context, FeedPostEntity post) async {
  AnalyticsService.logEvent('marketing_feed_report');
  final draft = await showDialog<_ReportDraft>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
  if (draft == null || !context.mounted) return;

  final error = await context.read<FeedReportCubit>().report(
    post.id,
    draft.reason,
    draft.note,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Laporan terkirim. Tim akan meninjau kiriman ini.')),
  );
}

class _ReportDraft {
  final String reason;
  final String? note;

  const _ReportDraft(this.reason, this.note);
}

/// Dialog dibuat sebagai widget sendiri agar [TextEditingController] dibuang di [dispose],
/// setelah dialog benar-benar hilang. Membuangnya sebelum animasi tutup selesai memicu
/// assertion `_dependents.isEmpty` (layar merah) saat Kirim ditekan.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _reason = FeedReportReason.spam.code;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _noteController.text.trim();
    Navigator.pop(context, _ReportDraft(_reason, note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                _reason == r.code ? Icons.radio_button_checked : Icons.radio_button_off,
                color: const Color(primaryColor),
                size: 20,
              ),
              onTap: () => setState(() => _reason = r.code),
            ),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Catatan (opsional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _submit, child: const Text('Kirim')),
      ],
    );
  }
}
