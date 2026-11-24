import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/marketing_feed/marketing_feed_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_comment_sheet.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_skeleton.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';

/// Satu kartu Wall of Fame di Home: kartu gelap berisi header pembuat,
/// nama kategori, poster (opsional), daftar juara dengan peringkat, dan caption.
class FameEntryTile extends StatefulWidget {
  final FameEntryEntity entry;

  const FameEntryTile({super.key, required this.entry});

  @override
  State<FameEntryTile> createState() => _FameEntryTileState();
}

class _FameEntryTileState extends State<FameEntryTile> {
  FameEntryEntity get entry => widget.entry;

  bool get _hasMedia => (entry.mediaUrl ?? '').isNotEmpty;

  /// Rasio video asli, diisi setelah video siap. Sebelum itu dipakai 16:9.
  double? _videoRatio;

  // Like, dislike, komentar, dan reaksi saya. Diperbarui optimistis, lalu disamakan dengan server.
  late int _likes = entry.likeCount;
  late int _dislikes = entry.dislikeCount;
  late int _comments = entry.commentCount;
  late FeedReaction _my = entry.myReaction;

  @override
  void didUpdateWidget(covariant FameEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final e = widget.entry;
    if (oldWidget.entry.id != e.id ||
        oldWidget.entry.likeCount != e.likeCount ||
        oldWidget.entry.dislikeCount != e.dislikeCount ||
        oldWidget.entry.commentCount != e.commentCount ||
        oldWidget.entry.myReaction != e.myReaction) {
      _likes = e.likeCount;
      _dislikes = e.dislikeCount;
      _comments = e.commentCount;
      _my = e.myReaction;
    }
  }

  /// Like / dislike: ketuk reaksi yang sama untuk membatalkan.
  Future<void> _react(FeedReaction target) async {
    final prevLikes = _likes;
    final prevDislikes = _dislikes;
    final prevMy = _my;
    final next = _my == target ? FeedReaction.none : target;
    setState(() {
      if (_my == FeedReaction.like) _likes--;
      if (_my == FeedReaction.dislike) _dislikes--;
      if (next == FeedReaction.like) _likes++;
      if (next == FeedReaction.dislike) _dislikes++;
      _my = next;
    });
    final res = await context.read<MarketingFeedCubit>().reactFameCard(
      entry.id,
      next,
    );
    if (!mounted) return;
    res.fold(
      (message) {
        setState(() {
          _likes = prevLikes;
          _dislikes = prevDislikes;
          _my = prevMy;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      (r) => setState(() {
        _likes = r.likes;
        _dislikes = r.dislikes;
        _my = r.myReaction;
      }),
    );
  }

  Future<void> _openComments() => showFameCommentSheet(
    context,
    cardId: entry.id,
    commentCount: _comments,
    onCountChanged: (n) {
      if (mounted) setState(() => _comments = n);
    },
  );

  /// Baris aksi di bawah kartu: like, dislike, dan komentar (seperti kiriman biasa).
  Widget _buildActions() {
    final muted = const Color(whiteColor).withValues(alpha: 0.85);
    Widget action(
      IconData icon,
      String label,
      bool active,
      VoidCallback onTap, {
      int activeColor = primaryColor,
    }) {
      final color = active ? Color(activeColor) : muted;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        action(
          _my == FeedReaction.like ? Icons.favorite : Icons.favorite_border,
          '$_likes',
          _my == FeedReaction.like,
          () => _react(FeedReaction.like),
          activeColor: redAccentColor,
        ),
        action(
          _my == FeedReaction.dislike
              ? Icons.thumb_down
              : Icons.thumb_down_outlined,
          '',
          _my == FeedReaction.dislike,
          () => _react(FeedReaction.dislike),
          activeColor: orangeAccentColor,
        ),
        action(Icons.chat_bubble_outline, '$_comments', false, _openComments),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard();
  }

  Widget _buildCard() {
    final caption = entry.caption?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(secondaryColor), Color(background2Color)],
        ),
        border: Border.all(
          color: const Color(whiteColor).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(grey4Color).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildTitleRow(),
          if (_hasMedia) ...[const SizedBox(height: 10), _buildPoster()],
          for (final w in entry.winners) _buildWinnerRow(w),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: const Color(whiteColor).withValues(alpha: 0.15),
            ),
            const SizedBox(height: 10),
            Text(
              caption,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: const Color(whiteColor).withValues(alpha: 0.92),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildActions(),
          const SizedBox(height: 6),
          // Sama seperti kartu feed: ringkasan komentar di bawah baris aksi.
          GestureDetector(
            onTap: _openComments,
            child: Text(
              _comments > 0
                  ? 'Lihat semua $_comments komentar'
                  : 'Jadi yang pertama berkomentar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(whiteColor).withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header: pembuat kartu, waktu tayang di bawah nama, dan pin kalau disematkan.
  Widget _buildHeader() {
    final when = entry.publishedAt == null
        ? ''
        : DateHelper.timeAgo(entry.publishedAt!);
    return Row(
      children: [
        FeedAvatar(
          name: entry.creatorName,
          initials: entry.creatorInitials,
          photoUrl: entry.creatorPhotoUrl,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.creatorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(whiteColor),
                ),
              ),
              if (when.isNotEmpty)
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(whiteColor).withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
        if (entry.isPinned)
          Icon(
            Icons.push_pin,
            size: 16,
            color: const Color(whiteColor).withValues(alpha: 0.7),
          ),
      ],
    );
  }

  /// Judul kategori (huruf besar) dengan piala, dan pill "N juara" hanya kalau juaranya lebih dari satu.
  Widget _buildTitleRow() {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events,
          size: 20,
          color: Color(amberMaterialColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entry.kategori.trim().toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: Color(whiteColor),
            ),
          ),
        ),
        if (entry.juaraCount > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(whiteColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${entry.juaraCount} juara',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(whiteColor),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Poster kartu dengan bingkai emas. Gambar mengikuti rasio aslinya, video diputar senyap.
  Widget _buildPoster() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(orangeAccentColor), width: 2),
      ),
      child: Stack(
        children: [
          _buildMedia(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: _buildPosterBar()),
          ),
        ],
      ),
    );
  }

  /// Bar di bawah poster: nama program (dengan piala) dan pill periode di kanan.
  Widget _buildPosterBar() {
    final program = entry.programName.trim();
    final periode = entry.periodeLabel?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 14,
            color: Color(orangeAccentColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              program,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(whiteColor),
              ),
            ),
          ),
          if (periode.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(whiteColor).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                periode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(whiteColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Satu juara: medali peringkat, nama, jabatan · tim, dan pill peringkat di kanan.
  Widget _buildWinnerRow(FameWinnerEntity w) {
    final sub = [
      w.posisiLabel,
      w.timLabel,
    ].where((s) => s != null && s.trim().isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(whiteColor).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(whiteColor).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _buildRankMedal(w),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(whiteColor),
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(whiteColor).withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildRankPill(w),
        ],
      ),
    );
  }

  /// Medali: #1 oranye, #2 perak, #3 perunggu, selain itu lingkaran berbingkai dengan angka.
  Widget _buildRankMedal(FameWinnerEntity w) {
    final rank = w.ranking;
    final BoxDecoration decoration;
    if (rank == 1) {
      decoration = const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(orangeAccentColor), Color(amberMaterialColor)],
        ),
      );
    } else if (rank == 2 || rank == 3) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Color(rank == 2 ? greyShade500 : feedBronzeColor),
      );
    } else {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(whiteColor).withValues(alpha: 0.7),
          width: 1.5,
        ),
      );
    }
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        w.rankText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Color(whiteColor),
        ),
      ),
    );
  }

  /// Pill peringkat: "#1 Juara" untuk juara tunggal #1, "#r Seri" untuk peringkat yang dibagi, selain itu "#r".
  Widget _buildRankPill(FameWinnerEntity w) {
    final gold = w.ranking == 1 || w.isSeri;
    // Cukup nomor peringkat, mis. "#1" (tanpa kata "Juara" atau "Seri").
    final label = '#${w.rankText}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: gold
            ? const Color(amberMaterialColor).withValues(alpha: 0.22)
            : const Color(whiteColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: gold
              ? const Color(amberMaterialColor).withValues(alpha: 0.6)
              : const Color(whiteColor).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: gold
              ? const Color(amberMaterialColor)
              : const Color(whiteColor).withValues(alpha: 0.8),
        ),
      ),
    );
  }

  /// Media poster: video (autoplay, tanpa suara, berulang) atau gambar dengan header auth.
  Widget _buildMedia() {
    final url = entry.mediaUrl!;
    if (entry.mediaType == 'video') {
      return AspectRatio(
        aspectRatio: _videoRatio ?? 16 / 9,
        child: OnScreenBuilder(
          builder: (context, visible) => FeedVideoPlayer(
            url: url,
            autoPlay: true,
            loop: true,
            muted: true,
            active: visible,
            hideControls:
                false, // tap = play/pause; autoplay & loop tetap jalan
            onAspectRatio: (r) {
              if (_videoRatio != r) setState(() => _videoRatio = r);
            },
            placeholder: _mediaPlaceholder(),
            fallback: _mediaPlaceholder(),
          ),
        ),
      );
    }
    // Gambar mengikuti rasio aslinya: lebar penuh kartu, tinggi menyesuaikan. Saat memuat, placeholder 16:9.
    return Image.network(
      url,
      headers: AuthTokenCache.getAuthHeadersFor(url),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const AspectRatio(
              aspectRatio: 16 / 9,
              child: FeedMediaSkeleton(),
            ),
      errorBuilder: (_, __, ___) =>
          AspectRatio(aspectRatio: 16 / 9, child: _mediaPlaceholder()),
    );
  }

  /// Placeholder saat media belum siap atau gagal, supaya poster tidak tampak kosong.
  Widget _mediaPlaceholder() {
    return Container(
      color: const Color(background2Color),
      alignment: Alignment.center,
      child: const Icon(
        Icons.emoji_events,
        size: 48,
        color: Color(orangeAccentColor),
      ),
    );
  }
}
