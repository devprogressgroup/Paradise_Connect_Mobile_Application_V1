import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_link_default_thumb.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Kartu yang sama untuk semua baris di Feeds (kiriman dan Wall of Fame).
/// Isi kartu ditentukan pemanggil lewat [feedPostCard] atau [fameListCard]; tombol di [footer] mengikuti status dan izin.
class FeedManageCard extends StatelessWidget {
  final Widget thumbnail;
  final Widget badge;
  final String title;
  final String? subtitle;
  final String timeText;
  final String? rejectReason;
  final VoidCallback onTap;

  /// Baris tombol di bawah kartu. Null = kartu tanpa tombol.
  final Widget? footer;

  const FeedManageCard({
    super.key,
    required this.thumbnail,
    required this.badge,
    required this.title,
    this.subtitle,
    required this.timeText,
    this.rejectReason,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: badge),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(grey4Color),
                          ),
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
            if (rejectReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(redAccentColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(redAccentColor).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(redAccentColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan penolakan: $rejectReason',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(redAccentColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  Widget? footer,
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
            child: Icon(Icons.image_not_supported_outlined, color: Color(grey4Color)),
          ),
    badge: FeedStatusBadge(post: post),
    title: post.text.isNotEmpty ? post.plainText : 'Momen tanpa cerita teks',
    timeText: post.submittedAt != null
        ? 'Dikirim ${DateHelper.timeAgo(post.submittedAt!)}'
        : 'Dikirim ${DateHelper.timeAgo(post.publishAt)}',
    rejectReason: post.status == FeedPostStatus.rejected ? post.rejectReason : null,
    onTap: onTap,
    footer: footer,
  );
}

/// Kartu Wall of Fame: poster (atau piala), kategori, program, dan badge status.
FeedManageCard fameListCard({
  required FameListCardEntity card,
  required VoidCallback onTap,
  Widget? footer,
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
    badge: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        const SizedBox(width: 6),
        FeedStatusPill.fame(card.status),
      ],
    ),
    title: card.kategori.trim().toUpperCase(),
    subtitle: [
      card.program,
      if (card.periode != null && card.periode!.isNotEmpty) card.periode!,
    ].where((s) => s.trim().isNotEmpty).join(' · '),
    timeText: created != null ? 'Dibuat ${DateHelper.timeAgo(created)}' : '',
    onTap: onTap,
    footer: footer,
  );
}

/// Label status kiriman (Menunggu review, Disetujui, Sudah tayang, Ditolak).
class FeedStatusBadge extends StatelessWidget {
  final FeedPostEntity post;

  const FeedStatusBadge({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    switch (post.status) {
      case FeedPostStatus.review:
        return const FeedStatusPill(
          label: 'Menunggu review',
          bg: orangeAccentColor,
          fg: orangeAccentColor,
        );
      case FeedPostStatus.scheduled:
        return FeedStatusPill(
          label: 'Disetujui, tayang ${DateHelper.relativeDayTime(post.publishAt)}',
          bg: blueShade50Color,
          fg: primaryColor,
          solidBg: true,
        );
      case FeedPostStatus.published:
        return const FeedStatusPill(
          label: 'Sudah tayang',
          bg: greenMaterialColor,
          fg: greenMaterialColor,
        );
      case FeedPostStatus.rejected:
        return const FeedStatusPill(
          label: 'Ditolak',
          bg: redAccentColor,
          fg: redAccentColor,
        );
      default:
        return FeedStatusPill(
          label: post.status.name,
          bg: grey10Color,
          fg: grey2Color,
          solidBg: true,
        );
    }
  }
}

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

  /// Badge status kartu Wall of Fame (draf, terjadwal, tayang).
  factory FeedStatusPill.fame(String status) {
    switch (status) {
      case 'published':
        return const FeedStatusPill(label: 'Tayang', bg: greenMaterialColor, fg: greenMaterialColor);
      case 'scheduled':
        return const FeedStatusPill(label: 'Terjadwal', bg: blueShade50Color, fg: primaryColor, solidBg: true);
      default:
        return const FeedStatusPill(label: 'Draf', bg: grey10Color, fg: grey2Color, solidBg: true);
    }
  }

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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(fg)),
      ),
    );
  }
}

/// Sematkan / lepas sematan di profil. Hanya ditampilkan untuk kiriman sendiri yang sudah tayang.
class FeedProfilePinButton extends StatelessWidget {
  final bool pinned;
  final VoidCallback? onPressed;

  const FeedProfilePinButton({
    super.key,
    required this.pinned,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          pinned ? Icons.push_pin : Icons.push_pin_outlined,
          size: 16,
        ),
        label: Text(pinned ? 'Lepas sematan' : 'Sematkan di profil'),
      ),
    );
  }
}
