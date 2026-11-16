import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_avatar.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_view.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Satu juara Wall of Fame sebagai kartu, sama seperti kartu kiriman lain di feed.
/// Juara #1 tampil besar (kartu gradasi), peringkat lain tampil ringkas.
class FameEntryTile extends StatefulWidget {
  final FameEntryEntity entry;

  const FameEntryTile({super.key, required this.entry});

  @override
  State<FameEntryTile> createState() => _FameEntryTileState();
}

class _FameEntryTileState extends State<FameEntryTile> {
  static const _defaultChampionHeight = 122.0;
  // Batas atas supaya video potret yang sangat tinggi tidak membuat kartu terlalu panjang.
  static const _maxChampionHeight = 420.0;

  /// Rasio lebar/tinggi video juara, diisi setelah video siap. Null = belum tahu (tinggi default).
  double? _videoAspect;

  FameEntryEntity get entry => widget.entry;

  bool get _hasVideo =>
      entry.mediaType == 'video' && (entry.mediaUrl ?? '').isNotEmpty;

  void _onVideoAspect(double aspect) {
    if (mounted && aspect != _videoAspect)
      setState(() => _videoAspect = aspect);
  }

  /// Video landscape -> kartu pendek, potret -> kartu tinggi, mengikuti rasio video asli.
  double _championHeight(double width) {
    final aspect = _videoAspect;
    final isVideo =
        entry.mediaType == 'video' && (entry.mediaUrl ?? '').isNotEmpty;
    if (aspect == null || !isVideo || aspect <= 0)
      return _defaultChampionHeight;
    return (width / aspect)
        .clamp(_defaultChampionHeight, _maxChampionHeight)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final label = [
      entry.kategori,
      entry.programName,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(primaryColor),
                  ),
                ),
              ),
              if (entry.isPinned)
                const Icon(
                  Icons.push_pin,
                  size: 14,
                  color: Color(primaryColor),
                ),
            ],
          ),
        ),
        entry.isChampion ? _buildChampion() : _buildRunnerUp(),
      ],
    );
  }

  Widget _buildChampion() {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: _championHeight(constraints.maxWidth),
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(secondaryColor), Color(background2Color)],
          ),
        ),
        child: Stack(
          children: [
            // Video khusus juara: diputar full-bleed di belakang kartu (seperti pratinjau Admin Web),
            // dengan gradasi gelap di bawah supaya teks tetap terbaca.
            if (entry.mediaType == 'video' &&
                (entry.mediaUrl ?? '').isNotEmpty) ...[
              Positioned.fill(
                child: OnScreenBuilder(
                  builder: (context, visible) => _buildMedia(
                    allowVideo: true,
                    visible: visible,
                    onAspectRatio: _onVideoAspect,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // Gelap di bagian atas (tempat teks juara), video di bawahnya tetap terlihat.
                      stops: const [0.0, 0.5],
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Penanda video (ikon play kecil di pojok kanan atas), seperti pratinjau Admin Web.
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: Color(whiteColor),
                  ),
                ),
              ),
            ],
            // Foto/inisial juara (tanpa video) tetap tampil di lingkaran kanan.
            if (entry.mediaType != 'video' || (entry.mediaUrl ?? '').isEmpty)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(whiteColor).withValues(alpha: 0.25),
                    ),
                    child: ClipOval(
                      child: OnScreenBuilder(
                        builder: (context, visible) =>
                            _buildMedia(allowVideo: true, visible: visible),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                decoration: BoxDecoration(
                  color: const Color(orangeAccentColor),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 13,
                      color: Color(whiteColor),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Juara #1',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(whiteColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              // Kartu video: teks di atas video (di bawah badge "Juara #1"), tanpa lingkaran foto di kanan.
              right: _hasVideo ? 44 : 112,
              top: _hasVideo ? 40 : null,
              bottom: _hasVideo ? null : 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.posisiLabel == null || entry.posisiLabel!.isEmpty
                        ? entry.name
                        : '${entry.name} · ${entry.posisiLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(whiteColor),
                    ),
                  ),
                  if (entry.caption != null && entry.caption!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: const Color(whiteColor).withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunnerUp() {
    return FeedCard(
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: ClipOval(child: _buildMedia()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (entry.posisiLabel != null && entry.posisiLabel!.isNotEmpty)
                  Text(
                    entry.posisiLabel!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(grey2Color),
                    ),
                  ),
                if (entry.caption != null && entry.caption!.isNotEmpty)
                  Text(
                    entry.caption!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(grey5Color),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '#${entry.ranking}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(grey2Color),
            ),
          ),
        ],
      ),
    );
  }

  /// Urutan fallback: video (hanya juara, [allowVideo]) -> gambar -> foto profil -> inisial.
  /// [visible] false (kartu keluar layar) men-pause video.
  Widget _buildMedia({
    bool allowVideo = false,
    bool visible = true,
    ValueChanged<double>? onAspectRatio,
  }) {
    final avatar = _avatar();
    final url = entry.mediaUrl;
    if (url == null || url.isEmpty) return avatar;

    if (entry.mediaType == 'video') {
      if (!allowVideo) return avatar;
      return FeedVideoPlayer(
        url: url,
        autoPlay: true,
        loop: true,
        muted: true,
        active: visible,
        hideControls: true,
        onAspectRatio: onAspectRatio,
        placeholder: avatar,
        fallback: avatar,
      );
    }

    if (entry.mediaType == 'image') {
      return Image.network(
        url,
        headers: AuthTokenCache.getAuthHeadersFor(url),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : avatar,
        errorBuilder: (_, __, ___) => avatar,
      );
    }
    return avatar;
  }

  Widget _avatar() {
    return FeedAvatar(
      name: entry.name,
      initials: entry.initials,
      photoUrl: entry.photoUrl,
      size: 76,
    );
  }
}
