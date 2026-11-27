import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_link_default_thumb.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Aksi satu kartu di Feeds. Ditampilkan lewat menu titik tiga, bukan tombol di kartu.
/// [onPressed] null = aksi nonaktif (mis. sedang diproses).
class FeedCardAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const FeedCardAction({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });
}

/// Tombol titik tiga yang membuka daftar [actions]. Dipakai juga di Detail Post, supaya aksi kiriman sama di semua layar.
Widget feedActionMenu(List<FeedCardAction> actions) {
  return SizedBox(
    width: 27,
    child: PopupMenuButton<FeedCardAction>(
      tooltip: 'Lainnya',
      icon: const Icon(Icons.more_vert, size: 20, color: Color(grey2Color)),
      padding: EdgeInsets.zero,
      onSelected: (a) => a.onPressed?.call(),
      itemBuilder: (_) => [
        for (final a in actions)
          PopupMenuItem<FeedCardAction>(
            value: a,
            enabled: a.onPressed != null,
            child: Row(
              children: [
                Icon(a.icon, size: 18, color: a.color),
                const SizedBox(width: 8),
                Text(a.label),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Kartu yang sama untuk semua baris di Feeds (kiriman dan Wall of Fame).
/// Isi kartu ditentukan pemanggil lewat [feedPostCard] atau [fameListCard]. Aksi dibuka dari menu titik tiga ([menu]).
class FeedManageCard extends StatelessWidget {
  final Widget thumbnail;
  final Widget badge;
  final String title;
  final String? subtitle;
  final String timeText;
  final VoidCallback onTap;

  /// Penanda di kiri baris atas (mis. pembuat kiriman atau label Wall of Fame). Null = hanya badge di kiri.
  final Widget? header;

  /// Keterangan di bawah kartu (mis. jumlah laporan). Null = tanpa keterangan.
  final Widget? footer;

  /// Aksi kartu untuk menu titik tiga (PopupMenuButton). Null atau kosong = kartu tanpa menu.
  final List<FeedCardAction>? menu;

  const FeedManageCard({
    super.key,
    required this.thumbnail,
    required this.badge,
    required this.title,
    this.subtitle,
    required this.timeText,
    required this.onTap,
    this.header,
    this.footer,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final actions = menu ?? const <FeedCardAction>[];
    // Panah dan titik tiga di kanan atas kartu. Menu titik tiga sama dengan menu "Laporkan" di Home.
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (actions.isNotEmpty) feedActionMenu(actions),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: feedCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 68, height: 68, child: thumbnail),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dengan header: penanda di kiri, badge status dan menu di kanan, sejajar dalam satu baris.
                      if (header != null)
                        Container(
                          height: 20,
                          child: Row(
                            children: [
                              Expanded(child: header!),
                              const SizedBox(width: 8),
                              // flex 0: badge pakai lebarnya sendiri dan tidak membagi ruang dengan nama.
                              Flexible(flex: 0, child: badge),
                              const SizedBox(width: 4),
                              trailing,
                            ],
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: badge),
                            trailing,
                          ],
                        ),
                                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(grey1Color),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(grey2Color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: 10), footer!],
          ],
        ),
      ),
    );
  }
}

/// Kartu kiriman.
FeedManageCard feedPostCard({
  required FeedPostEntity post,
  required VoidCallback onTap,
  FeedBadgeEntity? badge,
  Widget? footer,
  List<FeedCardAction>? menu,
}) {
  final thumb = post.thumbnail;
  return FeedManageCard(
    thumbnail: thumb != null
        ? FeedMediaView(media: thumb, compact: true)
        : post.link != null
        ? FeedLinkDefaultThumb(platform: post.link!.platform, compact: true)
        // Tanpa media: gambar dicoret sebagai default.
        : const ColoredBox(
            color: Color(grey10Color),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(grey4Color),
            ),
          ),
    badge: feedBadgeWidget(badge),
    // Kiriman biasa/poll: caption. Link: judul link (plainText), bila kosong baru pakai teks default.
    title: post.plainText.trim().isNotEmpty
        ? post.plainText
        : 'Momen tanpa cerita teks',
    timeText: post.status == FeedPostStatus.draft
        ? 'Disimpan ${DateHelper.timeAgo(post.publishAt)}'
        : post.submittedAt != null
        ? 'Dikirim ${DateHelper.timeAgo(post.submittedAt!)}'
        : 'Dikirim ${DateHelper.timeAgo(post.publishAt)}',
    onTap: onTap,
    header: FeedAuthorTag(author: post.author),
    footer: footer,
    menu: menu,
  );
}

/// Kartu Wall of Fame: poster (atau piala), kategori, program, dan badge status.
FeedManageCard fameListCard({
  required FameListCardEntity card,
  required VoidCallback onTap,
  FeedBadgeEntity? badge,
  Widget? footer,
  List<FeedCardAction>? menu,
}) {
  final url = card.mediaUrl;
  final created = card.submittedAt;
  return FeedManageCard(
    thumbnail: url != null
        ? FeedMediaView(
            media: FeedMediaEntity(url: url, isVideo: card.isVideo),
            compact: true,
          )
        : const ColoredBox(
            color: Color(grey10Color),
            child: Icon(Icons.emoji_events, color: Color(orangeAccentColor)),
          ),
    // Pembuat di kiri atas menggantikan label WALL OF FAME. Label tetap tampil kalau nama pembuat kosong.
    header: card.author != null && card.author!.name.trim().isNotEmpty
        ? FeedAuthorTag(author: card.author!)
        : Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(orangeAccentColor).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'WALL OF FAME',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(orangeAccentColor),
          ),
        ),
      ),
    ),
    badge: feedBadgeWidget(badge),
    title: card.kategori.trim().toUpperCase(),
    subtitle: [
      card.program,
      if (card.periode != null && card.periode!.isNotEmpty) card.periode!,
    ].where((s) => s.trim().isNotEmpty).join(' · '),
    timeText: created != null ? 'Dibuat ${DateHelper.timeAgo(created)}' : '',
    onTap: onTap,
    footer: footer,
    menu: menu,
  );
}

/// Avatar kecil + nama pembuat kiriman, dipakai sebagai header kartu.
class FeedAuthorTag extends StatelessWidget {
  final FeedAuthorEntity author;

  const FeedAuthorTag({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FeedAvatar(
          name: author.name,
          initials: author.initials,
          photoUrl: author.photoUrl,
          isModerator: author.isModerator,
          size: 18,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            author.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(grey1Color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge dari backend: label dan warna dari tone. Null (respons tanpa badge) = tidak tampil.
Widget feedBadgeWidget(FeedBadgeEntity? badge) {
  if (badge == null) return const SizedBox.shrink();
  final color = feedToneColor(badge.tone);
  return FeedStatusPill(label: badge.label, bg: color, fg: color);
}

/// Warna badge untuk tone dari backend. Tone yang tidak dikenal = abu-abu.
int feedToneColor(String tone) => switch (tone) {
  'red' => redAccentColor,
  'green' => greenMaterialColor,
  'blue' => primaryColor,
  'orange' => orangeAccentColor,
  _ => grey2Color,
};

/// Pill status yang dipakai badge kiriman dan kartu Wall of Fame.
/// [bg] dan [fg] berupa id warna dari core/constants/colors.dart. Latar bisa solid atau transparan 15%.
class FeedStatusPill extends StatelessWidget {
  final String label;
  final int bg;
  final int fg;
  final bool solidBg;

  const FeedStatusPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.solidBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = solidBg ? Color(bg) : Color(bg).withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(fg),
        ),
      ),
    );
  }
}
