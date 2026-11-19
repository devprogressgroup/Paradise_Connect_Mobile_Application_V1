import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_link_default_thumb.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_youtube_player.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_poll_box.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kartu satu item feed — post biasa, poll, atau link sosmed. Kiriman sendiri yang masih
/// direview/ditolak tampil dengan bingkai oranye & tanpa tombol interaksi.
class FeedPostCard extends StatelessWidget {
  final FeedPostEntity post;
  final ValueChanged<FeedReaction>? onReact;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final Future<String?> Function(List<int> optionIndexes)? onVote;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onReact,
    this.onComment,
    this.onShare,
    this.onVote,
  });

  bool get _isPending =>
      post.status == FeedPostStatus.review ||
      post.status == FeedPostStatus.rejected;

  BoxDecoration get _decoration => _isPending
      ? BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(
              post.status == FeedPostStatus.rejected
                  ? redAccentColor
                  : orangeAccentColor,
            ),
            width: 1.5,
          ),
        )
      : feedCardDecoration();

  @override
  Widget build(BuildContext context) => _withPin(_buildCard(context));

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
    if (post.type == FeedPostType.link) return _buildLinkCard();

    final showFooter = post.status == FeedPostStatus.published;
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _FeedPostFooter(
                post: post,
                onReact: onReact,
                onComment: onComment,
                onShare: onShare,
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final author = post.author;
    // Nama atau avatar pembuat membuka profilnya (kecuali akun resmi/moderator tanpa profil sales).
    void openProfile() {
      if (author.id > 0 && !author.isOfficial) {
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
      _ => 'Dikirim ${DateHelper.timeAgo(post.publishAt).toLowerCase()}',
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

  Widget _buildPendingTag() {
    final rejected = post.status == FeedPostStatus.rejected;
    final color = Color(rejected ? redAccentColor : orangeAccentColor);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          rejected ? Icons.block : Icons.hourglass_top_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            rejected
                ? 'Ditolak moderator: ${post.rejectReason ?? 'belum sesuai pedoman konten'}'
                : 'Menunggu tinjauan moderator',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard() {
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
            onTap: () => launchUrl(
              Uri.parse(link.url),
              mode: LaunchMode.externalApplication,
            ),
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
          if (post.status == FeedPostStatus.published)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _FeedPostFooter(
                post: post,
                onReact: onReact,
                onComment: onComment,
                onShare: onShare,
              ),
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
    // `**teks**` = tebal, `__teks__` = miring.
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*([\s\S]+?)\*\*|__([\s\S]+?)__');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(
        style: style,
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
  final VoidCallback? onShare;

  const _FeedPostFooter({
    required this.post,
    this.onReact,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final s = post.settings;
    final liked = post.myReaction == FeedReaction.like;
    final disliked = post.myReaction == FeedReaction.dislike;
    final latest = post.latestComment;
    final hasActions =
        s.allowLike ||
        s.allowDislike ||
        s.allowComment ||
        post.commentCount > 0 ||
        s.allowShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasActions)
          Row(
            children: [
              if (s.allowLike)
                _action(
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  color: liked ? const Color(redAccentColor) : null,
                  onTap: () => onReact?.call(FeedReaction.like),
                ),
              if (s.allowDislike)
                _action(
                  icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: '${post.dislikeCount}',
                  color: disliked ? const Color(orangeAccentColor) : null,
                  onTap: () => onReact?.call(FeedReaction.dislike),
                ),
              // Komentar dimatikan: input disembunyikan, tapi komentar lama tetap bisa dibuka.
              if (s.allowComment || post.commentCount > 0)
                _action(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentCount}',
                  onTap: onComment,
                ),
              const Spacer(),
              if (s.allowShare)
                _action(
                  icon: Icons.share_outlined,
                  label: 'Bagikan',
                  color: const Color(primaryColor),
                  onTap: onShare,
                  trailingGap: false,
                ),
            ],
          ),
        const SizedBox(height: 8),
        if (s.allowComment) ...[
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
        ] else
          const Row(
            children: [
              Icon(
                Icons.speaker_notes_off_outlined,
                size: 14,
                color: Color(grey4Color),
              ),
              SizedBox(width: 6),
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

  Widget _action({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    bool trailingGap = true,
  }) {
    final c = color ?? const Color(grey2Color);
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
              Icon(icon, size: 18, color: c),
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
          ),
        ),
      ),
    );
  }
}
