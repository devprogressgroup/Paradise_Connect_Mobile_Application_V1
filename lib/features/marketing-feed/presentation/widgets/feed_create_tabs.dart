import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';

/// Jenis konten yang bisa dibuat.
enum FeedCreateTab { postingan, polling, link }

/// Tab "Buat Konten" (Postingan / Polling / Link).
/// Setiap tab hanya tampil jika user punya permission untuk jenis kontennya (CreatePost / CreatePoll / CreateLink).
/// Tiap tab adalah route sendiri, jadi pindah tab memakai
/// pushReplacement: isi form yang belum disimpan di tab sebelumnya tidak ikut terbawa.
class FeedCreateTabs extends StatelessWidget {
  final FeedCreateTab current;

  const FeedCreateTabs({super.key, required this.current});

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
  ];

  static bool _allowed(FeedCreateTab tab) => switch (tab) {
    FeedCreateTab.postingan => PermissionsHelper.canCreateMarketingPost,
    FeedCreateTab.polling => PermissionsHelper.canCreateMarketingPoll,
    FeedCreateTab.link => PermissionsHelper.canCreateMarketingLink,
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
                  context.pushReplacementNamed(routeName);
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
