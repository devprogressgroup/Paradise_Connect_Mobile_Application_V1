import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_published/feed_published_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_post_card.dart';

/// Semua kiriman yang sedang tayang, dengan aksi turunkan tayang dan hapus.
/// Dipakai di tab Tayang untuk user dengan izin ApproveReject. User lain hanya melihat kiriman sendiri, tanpa aksi ini.
class FeedPublishedList extends StatefulWidget {
  const FeedPublishedList({super.key});

  @override
  State<FeedPublishedList> createState() => _FeedPublishedListState();
}

class _FeedPublishedListState extends State<FeedPublishedList> {
  static const _interval = Duration(seconds: 30);
  Timer? _timer;
  late final FeedPublishedCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<FeedPublishedCubit>();
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

  Future<void> _unpublish(int postId) async {
    final error = await _cubit.act(postId, 'unpub');
    _show(error ?? 'Kiriman diturunkan tayang dan kembali ke draf');
  }

  Future<void> _delete(int postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kiriman?'),
        content: const Text('Kiriman yang dihapus tidak tampil lagi di feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _cubit.act(postId, 'del');
    _show(error ?? 'Kiriman dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedPublishedCubit, FeedPublishedState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          if (state.status == FeedPublishedStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Gagal memuat kiriman tayang.'),
                  TextButton(onPressed: () => _cubit.load(), child: const Text('Coba lagi')),
                ],
              ),
            );
          }
          if (state.status == FeedPublishedStatus.loaded) {
            return const Center(
              child: Text(
                'Belum ada kiriman yang tayang',
                style: TextStyle(color: Color(grey2Color)),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => _cubit.load(),
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
                          onPressed: busy ? null : () => _unpublish(post.id),
                          child: const Text('Turunkan tayang'),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : () => _delete(post.id),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(redAccentColor)),
                          child: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Hapus'),
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
