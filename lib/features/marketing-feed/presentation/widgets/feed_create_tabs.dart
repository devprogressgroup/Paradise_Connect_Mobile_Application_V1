import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';

/// Jenis konten yang bisa dibuat. [wallOfFame] = unggah juara/kartu Wall of Fame (izin edit dari backend).
enum FeedCreateTab { postingan, polling, link, wallOfFame }

/// Tab "Buat Konten" (Postingan / Polling / Link).
/// Setiap tab hanya tampil jika user punya permission untuk jenis kontennya (CreatePost / CreatePoll / CreateLink).
/// Tiap tab adalah route sendiri, jadi pindah tab memakai
/// pushReplacement: isi form yang belum disimpan di tab sebelumnya tidak ikut terbawa.
class FeedCreateTabs extends StatelessWidget {
  final FeedCreateTab current;

  /// Query yang ikut dibawa saat pindah tab (mis. tanggal dan sumber kalender). Kosong = tanpa query.
  final Map<String, String> query;

  const FeedCreateTabs({
    super.key,
    required this.current,
    this.query = const {},
  });

  static const _items = <(FeedCreateTab, IconData, String, String)>[
    (
      FeedCreateTab.postingan,
      Icons.article_outlined,
      'Postingan',
      'marketingFeedPostForm',
    ),
    (
      FeedCreateTab.polling,
      Icons.poll_outlined,
      'Polling',
      'marketingFeedPollForm',
    ),
    (FeedCreateTab.link, Icons.link, 'Link', 'marketingFeedLinkForm'),
    (
      FeedCreateTab.wallOfFame,
      Icons.emoji_events_outlined,
      'Wall of Fame',
      'marketingFameForm',
    ),
  ];

  /// Izin Wall of Fame user (dari backend, t_feed_fame_perm). Diisi lewat [refreshFameAccess] saat feed dibuka.
  static bool fameEditable = false;

  /// Muat ulang hak akses Wall of Fame dari backend. Dipanggil saat feed dan Kiriman Saya dibuka.
  static Future<void> refreshFameAccess(BuildContext context) async {
    final cubit = context.read<FameManageCubit>();
    await cubit.load();
    fameEditable = cubit.state.access?.canEdit ?? false;
  }

  static bool _allowed(FeedCreateTab tab) => switch (tab) {
    FeedCreateTab.postingan => PermissionsHelper.canCreateMarketingPost,
    FeedCreateTab.polling => PermissionsHelper.canCreateMarketingPoll,
    FeedCreateTab.link => PermissionsHelper.canCreateMarketingLink,
    FeedCreateTab.wallOfFame => fameEditable,
  };

  /// Baris tab hanya tampil kalau user boleh membuat lebih dari satu jenis konten. Kalau hanya Postingan, tidak ada tab.
  static bool get showRow => _items.where((e) => _allowed(e.$1)).length > 1;

  @override
  Widget build(BuildContext context) {
    final items = _items.where((e) => _allowed(e.$1)).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(grey10Color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (tab, icon, label, routeName) in items)
            Expanded(
              child: _TabButton(
                icon: icon,
                label: label,
                selected: tab == current,
                onTap: () {
                  if (tab == current) return;
                  context.pushReplacementNamed(
                    routeName,
                    queryParameters: query,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(primaryColor)
        : const Color(grey2Color);
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(whiteColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
