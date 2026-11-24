import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_stats_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_live/feed_live_stats.dart';
import 'package:progress_group/features/marketing-feed/presentation/feed_external_link.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_formatted_text_controller.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_link_default_thumb.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_youtube_player.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_poll_box.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Posisi global sebuah widget (untuk sharePositionOrigin). Null kalau belum dirender.
Rect? _rectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Kartu satu item feed — post biasa, poll, atau link sosmed. Kiriman sendiri yang masih
/// direview/ditolak tampil dengan bingkai oranye & tanpa tombol interaksi.
class FeedPostCard extends StatelessWidget {
  final FeedPostEntity post;
  final ValueChanged<FeedReaction>? onReact;
  final VoidCallback? onComment;
  final void Function(Rect? origin)? onShare;
  final Future<String?> Function(List<int> optionIndexes)? onVote;

  /// Widget tambahan di dalam kartu, di bawah isi (dipakai untuk tombol moderasi).
  final Widget? footer;

  /// false = nama/avatar pembuat tidak membuka profil (dipakai di halaman profil itu sendiri).
  final bool linkAuthorProfile;

  /// true = hitungan dan komentar terbaru diperbarui lewat polling ([FeedLiveStats]) selama kartu di layar.
  /// Dipakai di Home dan profil. false = kartu dasar tanpa polling (dipakai di dalam kartu itu sendiri).
  final bool liveUpdates;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onReact,
    this.onComment,
    this.onShare,
    this.onVote,
    this.footer,
    this.linkAuthorProfile = true,
    this.liveUpdates = true,
  });

  bool get _isPending =>
      post.status == FeedPostStatus.review ||
      post.status == FeedPostStatus.rejected;

  BoxDecoration get _decoration => _isPending
      ? BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color(
              post.status == FeedPostStatus.rejected
                  ? redAccentColor
                  : orangeAccentColor,
            ).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(shadowColor).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        )
      : feedCardDecoration();

  @override
  Widget build(BuildContext context) {
    if (!liveUpdates) return _withPin(_buildCard(context));
    return FeedLiveWatch(
      postId: post.id,
      child: ValueListenableBuilder<FeedStatsEntity?>(
        valueListenable: FeedLiveStats.instance.of(post.id),
        builder: (context, live, _) {
          return FeedPostCard(
            post: live == null ? post : _withLive(post, live),
            onReact: onReact,
            onComment: onComment,
            onShare: onShare,
            onVote: onVote,
            footer: footer,
            linkAuthorProfile: linkAuthorProfile,
            liveUpdates: false,
          );
        },
      ),
    );
  }

  /// Hitungan dan komentar terbaru dari polling menggantikan nilai saat kartu ini dibuat.
  FeedPostEntity _withLive(FeedPostEntity p, FeedStatsEntity s) {
    final c = s.latestComments.isEmpty ? null : s.latestComments.first;
    return p.copyWith(
      likeCount: s.likes,
      dislikeCount: s.dislikes,
      commentCount: s.comments,
      latestComment: c == null
          ? null
          : FeedCommentEntity(
              id: c.id,
              author: FeedAuthorEntity(
                id: 0,
                name: c.authorName,
                initials: getInitials(c.authorName),
              ),
              text: c.body,
              createdAt: c.createdAt,
            ),
    );
  }

  /// Ikon pin selalu di pojok kanan atas kartu, untuk semua jenis kiriman yang disematkan.
  Widget _withPin(Widget card) {
    if (!post.isPinned) return card;
    return Stack(
      children: [
        card,
        const Positioned(
          top: 12,
          right: 12,
          child: Icon(Icons.push_pin, size: 16, color: Color(primaryColor)),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    if (post.type == FeedPostType.link) return _buildLinkCard(context);

    // Di daftar persetujuan (footer khusus) ikon tetap tampil, supaya terlihat izin yang diberikan pembuat.
    final showFooter = post.status == FeedPostStatus.published || footer != null;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isPending) ...[
                  _buildPendingTag(),
                  const SizedBox(height: 10),
                ],
                _buildHeader(context),
                if (post.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  FeedRichText(
                    post.text,
                    trailing: post.poll?.isMultiple == true
                        ? ' (boleh pilih lebih dari 1)'
                        : null,
                  ),
                ],
                if (post.type == FeedPostType.poll && post.poll != null) ...[
                  const SizedBox(height: 10),
                  FeedPollBox(
                    poll: post.poll!,
                    image: post.media.isNotEmpty ? post.media.first : null,
                    onVote: onVote,
                  ),
                ],
              ],
            ),
          ),
          if (post.type == FeedPostType.post && post.media.isNotEmpty)
            FeedMediaCarousel(media: post.media),
          if (showFooter)
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                footer == null ? 14 : 10,
              ),
              child: _FeedPostFooter(
                post: post,
                onReact: onReact,
                onComment: onComment,
                onShare: onShare,
                showCounts: post.status == FeedPostStatus.published,
              ),
            ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(14, showFooter ? 0 : 10, 14, 14),
              child: footer,
            )
          else if (!showFooter)
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final author = post.author;
    // Nama atau avatar pembuat membuka profilnya (kecuali akun resmi/moderator tanpa profil sales).
    void openProfile() {
      if (linkAuthorProfile && author.id > 0 && !author.isOfficial) {
        context.pushNamed(
          'marketingFeedProfile',
          queryParameters: {'user_id': '${author.id}'},
        );
      }
    }

    final scope = post.label ?? post.project;
    final subtitle = switch (post.status) {
      FeedPostStatus.published =>
        scope == null
            ? DateHelper.timeAgo(post.publishAt)
            : '${DateHelper.timeAgo(post.publishAt)} · $scope',
      FeedPostStatus.scheduled =>
        'Terjadwal · ${DateHelper.relativeDayTime(post.publishAt)}',
      FeedPostStatus.draft => 'Draft',
      _ => 'Dikirim ${DateHelper.timeAgo(post.submittedAt ?? post.publishAt).toLowerCase()}',
    };
    return Row(
      children: [
        GestureDetector(
          onTap: openProfile,
          child: FeedAvatar(
            name: author.name,
            initials: author.initials,
            photoUrl: author.photoUrl,
            isModerator: author.isModerator,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: openProfile,
                child: Text(
                  author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Label status kiriman yang masih menunggu/ditolak, tampil sebagai pil berwarna lembut.
  Widget _buildPendingTag() {
    final rejected = post.status == FeedPostStatus.rejected;
    final color = Color(rejected ? redAccentColor : orangeAccentColor);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rejected ? Icons.block : Icons.hourglass_top_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              rejected
                  ? 'Ditolak moderator: ${post.rejectReason ?? 'belum sesuai pedoman konten'}'
                  : 'Menunggu tinjauan moderator',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context) {
    final link = post.link!;
    final cover = post.thumbnail == null && !link.isYoutube
        ? FeedLinkDefaultThumb(platform: link.platform)
        : FeedMediaView(
            media: post.thumbnail ?? FeedMediaEntity(isVideo: link.isYoutube),
          );
    // YouTube diputar inline seperti video postingan (WebView di mobile, iframe di web).
    final youtubeId = link.isYoutube ? youtubeVideoIdFromUrl(link.url) : null;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pembuat dan waktu tayang, sama seperti kiriman biasa.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: _buildHeader(context),
          ),
          if (youtubeId != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: OnScreenBuilder(
                builder: (context, visible) => FeedYoutubePlayer(
                  videoId: youtubeId,
                  visible: visible,
                  poster: cover,
                ),
              ),
            ),
          InkWell(
            onTap: () => openExternalFeedLink(context, link.url),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube yang tidak diputar inline (web) tetap thumbnail 16:9; website banner pendek.
                if (youtubeId == null && link.isYoutube)
                  AspectRatio(aspectRatio: 16 / 9, child: cover)
                else if (youtubeId == null)
                  SizedBox(height: 132, width: double.infinity, child: cover),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (link.sourceLabel != null)
                        Text(
                          link.sourceLabel!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(grey2Color),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Judul + ikon pin di kanan kalau kiriman link ini disematkan.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              link.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (link.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          link.description!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(grey2Color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.status == FeedPostStatus.published || footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _FeedPostFooter(
                post: post,
                onReact: onReact,
                onComment: onComment,
                onShare: onShare,
                showCounts: post.status == FeedPostStatus.published,
              ),
            ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                0,
                14,
                14,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// Teks caption — bagian yang diapit `**` ditampilkan tebal.
class FeedRichText extends StatelessWidget {
  final String text;
  final String? trailing;
  final TextStyle style;

  const FeedRichText(
    this.text, {
    super.key,
    this.trailing,
    this.style = const TextStyle(
      fontSize: 13.5,
      height: 1.5,
      color: Color(blackColor),
    ),
  });

  @override
  Widget build(BuildContext context) {
    // `**` = tebal, `__` = miring (bisa bersarang). Penanda tidak ditampilkan.
    final spans = <TextSpan>[
      for (final t in tokenizeFeedCaption(text))
        if (!t.marker)
          TextSpan(
            text: text.substring(t.start, t.end),
            style: TextStyle(
              fontWeight: t.bold ? FontWeight.bold : null,
              fontStyle: t.italic ? FontStyle.italic : null,
            ),
          ),
    ];
    return Text.rich(
      TextSpan(
        // Nunito Sans tidak punya glyph emoji: sediakan font cadangan emoji supaya tidak tampil kotak.
        style: style.copyWith(
          fontFamilyFallback: const [
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
          ],
        ),
        children: [
          ...spans,
          if (trailing != null)
            TextSpan(
              text: trailing,
              style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
            ),
        ],
      ),
    );
  }
}

class _FeedPostFooter extends StatelessWidget {
  final FeedPostEntity post;
  final ValueChanged<FeedReaction>? onReact;
  final VoidCallback? onComment;
  final void Function(Rect? origin)? onShare;
  // Jumlah like dan komentar. Pengajuan (menunggu persetujuan) hanya menampilkan ikon.
  final bool showCounts;

  const _FeedPostFooter({
    required this.post,
    this.onReact,
    this.onComment,
    this.onShare,
    this.showCounts = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = post.settings;
    final liked = post.myReaction == FeedReaction.like;
    final disliked = post.myReaction == FeedReaction.dislike;
    final latest = post.latestComment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris aksi selalu tampil: aksi yang dimatikan tetap terlihat dicoret.
        Row(
          children: [
            if (s.allowLike)
              _action(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                label: showCounts ? '${post.likeCount}' : '',

                color: liked ? const Color(redAccentColor) : null,
                onTap: () => onReact?.call(FeedReaction.like),
              )
            else
              _disabledAction(
                context,
                icon: Icons.favorite_border,
                label: showCounts ? '${post.likeCount}' : '',
                message: 'Suka dinonaktifkan untuk post ini',
              ),
            // Dislike: hanya ikon yang tampil, angkanya disembunyikan.
            if (s.allowDislike)
              _action(
                icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                label: '',
                color: disliked ? const Color(orangeAccentColor) : null,
                onTap: () => onReact?.call(FeedReaction.dislike),
              )
            else
              _disabledAction(
                context,
                icon: Icons.thumb_down_outlined,
                label: '',
                message: 'Dislike dinonaktifkan untuk post ini',
              ),
            // Komentar dimatikan: ikon tetap tampil (dicoret), ketuk memunculkan snackbar.
            // Komentar lama tetap bisa dibuka kalau sudah ada.
            if (s.allowComment || post.commentCount > 0)
              _action(
                icon: Icons.chat_bubble_outline,
                label: showCounts ? '${post.commentCount}' : '',
                onTap: onComment,
              )
            else
              _disabledAction(
                context,
                icon: Icons.chat_bubble_outline,
                label: showCounts ? '${post.commentCount}' : '',
                message: 'Komentar dinonaktifkan untuk post ini',
              ),
            if (s.allowShare)
              _action(
                icon: Icons.share_outlined,
                label: '',
                onTap: onShare == null
                    ? null
                    : () => onShare!(_rectOf(context)),
                trailingGap: false,
              )
            else
              _disabledAction(
                context,
                icon: Icons.share_outlined,
                label: '',
                message: 'Berbagi dinonaktifkan untuk post ini',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!showCounts && !s.allowComment)
          const Row(
            children: [
              Text(
                'Komentar dinonaktifkan untuk post ini',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(grey4Color),
                ),
              ),
            ],
          )
        else if (s.allowComment && showCounts) ...[
          if (latest != null) ...[
            GestureDetector(
              onTap: onComment,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(blackColor),
                  ),
                  children: [
                    TextSpan(
                      text: latest.author.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${latest.text}'),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
          ],
          GestureDetector(
            onTap: onComment,
            child: Text(
              post.commentCount > 0
                  ? 'Lihat semua ${post.commentCount} komentar'
                  : 'Jadi yang pertama berkomentar',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(grey2Color),
              ),
            ),
          ),
        ] else if (showCounts)
          const Row(
            children: [
              Text(
                'Komentar dinonaktifkan untuk post ini',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(grey4Color),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Aksi yang dimatikan di post: ikon dasar yang sama dengan saat aktif, diberi garis coret
  /// diagonal dan warna abu-abu redup. Ketuk tetap menampilkan snackbar alasannya.
  Widget _disabledAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String message,
  }) {
    return _action(
      icon: icon,
      label: label,
      color: const Color(grey4Color),
      disabled: true,
      onTap: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message))),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    bool trailingGap = true,
    bool disabled = false,
  }) {
    final c = color ?? const Color(grey2Color);
    final iconWidget = Icon(icon, size: 18, color: c);
    return Padding(
      padding: EdgeInsets.only(right: trailingGap ? 12 : 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (disabled)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      iconWidget,
                      CustomPaint(painter: _SlashPainter(color: c)),
                    ],
                  ),
                )
              else
                iconWidget,
              if (label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Garis coret diagonal (kiri bawah ke kanan atas) untuk menandai aksi yang dimatikan.
class _SlashPainter extends CustomPainter {
  const _SlashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const pad = 2.0;
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - pad, pad),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SlashPainter oldDelegate) =>
      oldDelegate.color != color;
}
