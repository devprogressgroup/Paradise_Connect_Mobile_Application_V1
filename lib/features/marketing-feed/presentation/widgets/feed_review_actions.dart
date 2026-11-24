import 'package:flutter/material.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_list/feed_list_cubit.dart';

/// Aksi per kiriman untuk daftar Feeds. Tiap fungsi menampilkan SnackBar hasilnya.
/// Tombol yang muncul ditentukan di layar (izin dan status), fungsi ini hanya menjalankan aksinya.

void _show(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> approveFeed(BuildContext context, FeedListCubit cubit, int postId) async {
  final error = await cubit.decide(postId, 'approve');
  if (!context.mounted) return;
  _show(context, error ?? 'Kiriman disetujui dan tayang');
}

/// Pilih tanggal dan jam tayang, lalu kirim sebagai jadwal ("yyyy-MM-dd HH:mm").
Future<void> scheduleFeed(BuildContext context, FeedListCubit cubit, int postId) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(hours: 1)),
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
  );
  if (time == null || !context.mounted) return;

  final at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (!at.isAfter(DateTime.now())) {
    _show(context, 'Waktu tayang harus di masa depan');
    return;
  }
  String two(int n) => n.toString().padLeft(2, '0');
  final publishAt =
      '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
  final error = await cubit.decide(postId, 'schedule', publishAt: publishAt);
  if (!context.mounted) return;
  _show(context, error ?? 'Kiriman dijadwalkan tayang');
}

Future<void> rejectFeed(BuildContext context, FeedListCubit cubit, int postId) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const _RejectDialog(),
  );
  if (reason == null || reason.isEmpty || !context.mounted) return;
  final error = await cubit.decide(postId, 'reject', reason: reason);
  if (!context.mounted) return;
  _show(context, error ?? 'Kiriman ditolak');
}

Future<void> unpublishFeed(BuildContext context, FeedListCubit cubit, int postId) async {
  final error = await cubit.moderate(postId, 'unpub');
  if (!context.mounted) return;
  _show(context, error ?? 'Kiriman diturunkan tayang dan kembali ke draf');
}

Future<void> deleteFeed(BuildContext context, FeedListCubit cubit, int postId) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus kiriman?'),
      content: const Text('Kiriman yang dihapus tidak tampil lagi di feed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final error = await cubit.moderate(postId, 'del');
  if (!context.mounted) return;
  _show(context, error ?? 'Kiriman dihapus');
}

/// Dialog alasan penolakan. Mengembalikan alasan yang diisi, atau null kalau dibatalkan.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak kiriman'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'Alasan penolakan (wajib)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
