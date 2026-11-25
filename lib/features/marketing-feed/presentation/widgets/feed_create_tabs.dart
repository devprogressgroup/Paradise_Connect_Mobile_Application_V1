import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/fame_manage/fame_manage_cubit.dart';

/// Jenis konten yang bisa dibuat. [wallOfFame] = unggah juara/kartu Wall of Fame (izin edit dari backend).
enum FeedCreateTab { postingan, polling, link, wallOfFame }

/// Pemilih "Tipe post": kartu yang menampilkan jenis aktif dengan tombol Ganti, lalu bottom sheet berisi pilihan.
/// Setiap tab hanya tampil jika user punya permission untuk jenis kontennya (CreatePost / CreatePoll / CreateLink).
/// Tiap jenis adalah route sendiri, jadi pindah jenis memakai
/// pushReplacement: isi form yang belum disimpan di jenis sebelumnya tidak ikut terbawa.
class FeedCreateTabs extends StatefulWidget {
  final FeedCreateTab current;

  /// Query yang ikut dibawa saat pindah jenis (mis. tanggal dan sumber kalender). Kosong = tanpa query.
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

  /// Pemilih hanya tampil kalau user boleh membuat lebih dari satu jenis konten. Kalau hanya Postingan, tidak ada.
  static bool get showRow => _items.where((e) => _allowed(e.$1)).length > 1;

  @override
  State<FeedCreateTabs> createState() => _FeedCreateTabsState();

  Widget buildRow(BuildContext context) {
    final items = _items.where((e) => _allowed(e.$1)).toList();
    // Pemilih hanya tampil kalau ada lebih dari satu jenis konten yang boleh dibuat.
    if (items.length < 2) return const SizedBox.shrink();

    final active = items.firstWhere(
      (e) => e.$1 == current,
      orElse: () => items.first,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context, items),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(primaryColor), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(active.$2, size: 20, color: const Color(primaryColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipe post',
                    style: TextStyle(fontSize: 11, color: Color(grey2Color)),
                  ),
                  Text(
                    active.$3,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Ganti',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(primaryColor),
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: Color(primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _openPicker(
    BuildContext context,
    List<(FeedCreateTab, IconData, String, String)> items,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(whiteColor),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PILIH TIPE POST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(grey2Color),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
                children: [
                  for (final (tab, icon, label, routeName) in items)
                    _TypeOption(
                      icon: icon,
                      label: label,
                      subtitle: _subtitle(tab),
                      selected: tab == current,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        if (tab == current) return;
                        context.pushReplacementNamed(
                          routeName,
                          queryParameters: query,
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(FeedCreateTab tab) => switch (tab) {
    FeedCreateTab.postingan => 'Foto & teks',
    FeedCreateTab.polling => 'Buat votingan',
    FeedCreateTab.link => 'Bagikan tautan',
    FeedCreateTab.wallOfFame => 'Apresiasi sales',
  };
}

class _FeedCreateTabsState extends State<FeedCreateTabs> {
  @override
  void initState() {
    super.initState();
    // Hak akses Wall of Fame dimuat di sini, jadi pilihan ikut muncul walau halaman dibuka langsung (mis. PWA).
    FeedCreateTabs.refreshFameAccess(context).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => widget.buildRow(context);
}

/// Satu pilihan di bottom sheet "Pilih tipe post".
class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(primaryColor) : const Color(grey1Color);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(primaryColor).withValues(alpha: 0.08)
              : const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(primaryColor)
                : const Color(grey10Color),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(grey10Color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(grey2Color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
