import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_report_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_report/feed_report_cubit.dart';

/// Menu titik tiga di pojok kanan atas kartu Home (kiriman, atau kartu Wall of Fame lewat [fame]).
/// Isinya "Laporkan" (atau "Sudah dilaporkan"). Isi [post] atau [fame], salah satu.
class FeedReportMenuButton extends StatelessWidget {
  final FeedPostEntity? post;
  final FameEntryEntity? fame;

  const FeedReportMenuButton({super.key, this.post, this.fame})
    : assert(post != null || fame != null);

  /// Sudah dilaporkan: dari server (my_report) atau baru dikirim di sesi ini.
  bool _isReported(FeedReportState s) => post != null
      ? post!.reportedByMe || s.reportedIds.contains(post!.id)
      : fame!.myReport || s.reportedFameIds.contains(fame!.id);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedReportCubit, FeedReportState>(
      buildWhen: (a, b) => _isReported(a) != _isReported(b),
      builder: (context, state) {
        final reported = _isReported(state);
        return Container(
          width: 27,
          child: PopupMenuButton<String>(
            tooltip: 'Lainnya',
            icon: const Icon(Icons.more_vert, size: 20, color: Color(grey2Color)),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value != 'report') return;
              if (post != null) {
                showReportPostDialog(context, post!);
              } else {
                showReportFameDialog(context, fame!);
              }
            },
            itemBuilder: (_) => [
              if (reported)
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('Sudah dilaporkan'),
                    ],
                  ),
                )
              else
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Laporkan'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Pilih alasan dan catatan opsional, lalu kirim laporan. Approver diberi tahu lewat notifikasi di server.
Future<void> showReportPostDialog(BuildContext context, FeedPostEntity post) {
  return _showReportSheet(
    context,
    title: 'Laporkan kiriman',
    submit: (cubit, reason, note) => cubit.report(post.id, reason, note),
    successMessage: 'Laporan terkirim. Tim akan meninjau kiriman ini.',
  );
}

/// Sama dengan [showReportPostDialog], untuk kartu Wall of Fame (endpoint wall-of-fame/cards/{id}/report).
Future<void> showReportFameDialog(BuildContext context, FameEntryEntity card) {
  return _showReportSheet(
    context,
    title: 'Laporkan kartu',
    submit: (cubit, reason, note) => cubit.reportFame(card.id, reason, note),
    successMessage: 'Laporan terkirim. Tim akan meninjau kiriman ini.',
  );
}

/// Bottom sheet laporan bersama. [submit] memilih endpoint; pesan sukses dari server dipakai kalau ada.
Future<void> _showReportSheet(
  BuildContext context, {
  required String title,
  required Future<String?> Function(FeedReportCubit cubit, String reason, String? note) submit,
  required String successMessage,
}) async {
  AnalyticsService.logEvent('marketing_feed_report');
  final draft = await showDialog<_ReportDraft>(
    context: context,
    builder: (_) => _ReportDialog(title: title),
  );
  if (draft == null || !context.mounted) return;

  final error = await submit(context.read<FeedReportCubit>(), draft.reason, draft.note);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? successMessage)),
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
  final String title;

  const _ReportDialog({this.title = 'Laporkan kiriman'});

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
      title: Text(widget.title),
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
