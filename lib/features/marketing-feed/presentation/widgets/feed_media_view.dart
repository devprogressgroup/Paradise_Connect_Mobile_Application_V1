import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:video_player/video_player.dart';

/// Satu foto/video, mengisi penuh kotaknya. File lokal (baru dipilih) ditampilkan dari bytes;
/// media dari server dimuat dengan authorization header bila diarahkan ke endpoint privat.
class FeedMediaView extends StatelessWidget {
  final FeedMediaEntity media;
  final bool compact;
  final bool autoPlayVideo;

  const FeedMediaView({
    super.key,
    required this.media,
    this.compact = false,
    this.autoPlayVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = media.bytes;
    final url = media.url;

    if (!media.isVideo && bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    if (!media.isVideo && url != null && url.isNotEmpty) {
      return Image.network(
        url,
        headers: AuthTokenCache.getAuthHeadersFor(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) => progress == null ? child : _placeholder(loading: true),
        errorBuilder: (_, error, __) {
          debugPrint('FeedMediaView gagal memuat $url: $error');
          return _placeholder();
        },
      );
    }

    if (media.isVideo && url != null && url.isNotEmpty && !compact) {
      return FeedVideoPlayer(
        url: url,
        autoPlay: autoPlayVideo,
        loop: autoPlayVideo,
        muted: autoPlayVideo,
      );
    }

    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) {
    final label = loading ? null : media.label ?? media.fileName;
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(compact ? 6 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(grey10Color), Color(blueShade50Color)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            media.isVideo ? Icons.play_circle_fill_rounded : Icons.image_outlined,
            size: compact ? 22 : 40,
            color: media.isVideo ? const Color(primaryColor) : const Color(grey4Color),
          ),
          if (label != null && !compact) ...[
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(grey2Color)),
            ),
          ],
        ],
      ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final bool loop;
  final bool muted;

  const FeedVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.loop = false,
    this.muted = false,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final headers = AuthTokenCache.getAuthHeadersFor(widget.url);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: headers,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      if (widget.muted) {
        _controller.setVolume(0.0);
      }
      if (widget.loop) {
        _controller.setLooping(true);
      }
      if (widget.autoPlay) {
        _controller.play();
      }
      setState(() => _initialized = true);
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_outlined, color: Color(grey4Color), size: 36),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
        ],
      ),
    );
  }
}

/// Galeri media post: satu media tampil persegi/rasio aslinya, lebih dari satu bisa di-swipe dengan penanda
/// "1/4" dan titik halaman.
class FeedMediaCarousel extends StatefulWidget {
  final List<FeedMediaEntity> media;

  const FeedMediaCarousel({super.key, required this.media});

  @override
  State<FeedMediaCarousel> createState() => _FeedMediaCarouselState();
}

class _FeedMediaCarouselState extends State<FeedMediaCarousel> {
  int _page = 0;

  double _getAspectRatio(FeedMediaEntity m) {
    if (m.width != null && m.height != null && m.height! > 0) {
      return (m.width! / m.height!).clamp(0.65, 1.8);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      final ratio = _getAspectRatio(media.first);
      return AspectRatio(aspectRatio: ratio, child: FeedMediaView(media: media.first));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: media.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => FeedMediaView(media: media[i]),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(blue2Color).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${_page + 1}/${media.length}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(whiteColor)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < media.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? const Color(whiteColor)
                          : const Color(whiteColor).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(color: const Color(blackColor).withValues(alpha: 0.3), blurRadius: 2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
