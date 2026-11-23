import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_review/feed_review_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';

/// Daftar kiriman sales yang menunggu persetujuan, dengan tombol Setujui dan Tolak.
/// Dipakai di tab Persetujuan (Feeds). Hanya untuk user dengan izin ApproveReject.
class FeedApprovalList extends StatefulWidget {
  const FeedApprovalList({super.key});

  @override
  State<FeedApprovalList> createState() => _FeedApprovalListState();
}

class _FeedApprovalListState extends State<FeedApprovalList> {
  // Kiriman baru dari sales muncul sendiri selama tab ini terbuka.
  static const _interval = Duration(seconds: 15);
  Timer? _timer;
  late final FeedReviewCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<FeedReviewCubit>();
    _cubit.load();
    _timer = Timer.periodic(_interval, (_) => _cubit.load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(int postId) async {
    final error = await context.read<FeedReviewCubit>().decide(postId, 'approve');
    _show(error ?? 'Kiriman disetujui dan tayang');
  }

  /// Pilih tanggal dan jam tayang, lalu kirim sebagai jadwal ("yyyy-MM-dd HH:mm").
  Future<void> _schedule(int postId) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!at.isAfter(DateTime.now())) {
      _show('Waktu tayang harus di masa depan');
      return;
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final publishAt =
        '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
    final error = await context.read<FeedReviewCubit>().decide(
      postId,
      'schedule',
      publishAt: publishAt,
    );
    _show(error ?? 'Kiriman dijadwalkan tayang');
  }

  Future<void> _reject(int postId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null || reason.isEmpty) return;
    final error = await context.read<FeedReviewCubit>().decide(
      postId,
      'reject',
      reason: reason,
    );
    _show(error ?? 'Kiriman ditolak');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedReviewCubit, FeedReviewState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          if (state.status == FeedReviewStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Gagal memuat antrean persetujuan.'),
                  TextButton(
                    onPressed: () => context.read<FeedReviewCubit>().load(),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }
          if (state.status == FeedReviewStatus.loaded) {
            return const Center(
              child: Text(
                'Tidak ada kiriman yang menunggu persetujuan',
                style: TextStyle(color: Color(grey2Color)),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => context.read<FeedReviewCubit>().load(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final post = state.items[i];
              final busy = state.busyId == post.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    FeedPostCard(key: ValueKey(post.id), post: post),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: busy ? null : () => _reject(post.id),
                          child: const Text('Tolak'),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : () => _schedule(post.id),
                          child: const Text('Jadwalkan'),
                        ),
                        FilledButton(
                          onPressed: busy ? null : () => _approve(post.id),
                          child: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Setujui'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
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
