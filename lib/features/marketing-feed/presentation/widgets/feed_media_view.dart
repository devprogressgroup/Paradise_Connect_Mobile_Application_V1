import 'dart:async';

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_media_skeleton.dart';
import 'package:video_player/video_player.dart';

/// Satu foto/video, mengisi penuh kotaknya. File lokal (baru dipilih) ditampilkan dari bytes;
/// media dari server dimuat dengan authorization header bila diarahkan ke endpoint privat.
class FeedMediaView extends StatelessWidget {
  final FeedMediaEntity media;
  final bool compact;
  final bool autoPlayVideo;

  /// false = video belum/tidak perlu diputar (kartu di luar layar); lihat [FeedVideoPlayer.active].
  final bool active;

  const FeedMediaView({
    super.key,
    required this.media,
    this.compact = false,
    this.autoPlayVideo = false,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = media.bytes;
    final url = media.url;

    if (!media.isVideo && bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (!media.isVideo && url != null && url.isNotEmpty) {
      return Image.network(
        url,
        headers: AuthTokenCache.getAuthHeadersFor(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : FeedMediaSkeleton(isVideo: media.isVideo),
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
        active: active,
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    final label = media.label ?? media.fileName;
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
            media.isVideo
                ? Icons.play_circle_fill_rounded
                : Icons.image_outlined,
            size: compact ? 22 : 40,
            color: media.isVideo
                ? const Color(primaryColor)
                : const Color(grey4Color),
          ),
          if (label != null && !compact) ...[
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(grey2Color),
              ),
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

  /// Ditampilkan sebelum video siap (mis. foto profil). Null = spinner.
  final Widget? placeholder;

  /// Ditampilkan kalau video gagal dimuat (jaringan, 404, dll.). Null = ikon video mati.
  final Widget? fallback;

  /// false = video di-pause (kartu keluar layar). Saat kembali true dan [autoPlay] aktif, diputar lagi.
  final bool active;

  /// Sembunyikan ikon play dan tap-to-toggle (untuk video dekoratif yang berulang).
  final bool hideControls;

  /// Dipanggil sekali video siap, dengan rasio lebar/tinggi video (untuk menyesuaikan tinggi kartu).
  final ValueChanged<double>? onAspectRatio;

  const FeedVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.loop = false,
    this.muted = false,
    this.placeholder,
    this.fallback,
    this.active = true,
    this.hideControls = false,
    this.onAspectRatio,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  late bool _muted;

  /// Controller baru dibuat saat video pertama kali terlihat (active), supaya kartu yang baru
  /// masuk cache render tidak langsung men-decode video dan membuat scroll tersendat.
  bool _created = false;

  @override
  void initState() {
    _muted = widget.muted;
    super.initState();
    if (widget.active) _initVideo();
  }

  /// Header Authorization hanya untuk URL yang belum bertanda tangan (tanpa query signature).
  Map<String, String> _headersFor(String url) {
    final uri = Uri.parse(url);
    final signed = uri.queryParameters.keys.any((k) {
      final key = k.toLowerCase();
      return key.contains('signature') ||
          key == 'sig' ||
          key.startsWith('x-amz-');
    });
    return signed ? const {} : AuthTokenCache.getAuthHeadersFor(url);
  }

  void _initVideo() {
    _created = true;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: _headersFor(widget.url),
    );
    _controller.addListener(_onControllerUpdate);

    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller.setVolume(_muted ? 0.0 : 1.0);
          if (widget.loop) {
            _controller.setLooping(true);
          }
          if (widget.autoPlay && widget.active) {
            _controller.play();
          }
          final size = _controller.value.size;
          if (size.width > 0 && size.height > 0) {
            widget.onAspectRatio?.call(size.width / size.height);
          }
          setState(() => _initialized = true);
        })
        .catchError((Object error) {
          debugPrint('FeedVideoPlayer gagal memuat ${widget.url}: $error');
          if (mounted) setState(() => _hasError = true);
        });
  }

  /// Error setelah video sudah berjalan (mis. jaringan putus) juga pindah ke fallback.
  void _onControllerUpdate() {
    if (mounted && !_hasError && _controller.value.hasError) {
      debugPrint(
        'FeedVideoPlayer error saat diputar ${widget.url}: ${_controller.value.errorDescription}',
      );
      setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active || _hasError) return;
    if (!_created) {
      if (widget.active) _initVideo();
      return;
    }
    if (!_initialized) return;
    if (!widget.active) {
      _controller.pause();
    } else if (widget.autoPlay) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    if (_created) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ??
          Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(
              Icons.videocam_off_outlined,
              color: Color(grey4Color),
              size: 36,
            ),
          );
    }

    if (!_initialized) {
      return widget.placeholder ?? const FeedMediaSkeleton(isVideo: true);
    }

    final video = Stack(
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
        if (!widget.hideControls && !_controller.value.isPlaying)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
      ],
    );

    if (widget.hideControls) return video;

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          video,
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _muted = !_muted);
                _controller.setVolume(_muted ? 0.0 : 1.0);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
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
      return AspectRatio(
        aspectRatio: ratio,
        // Video tunggal baru diinisialisasi saat kartunya terlihat di layar.
        child: OnScreenBuilder(
          builder: (context, visible) =>
              FeedMediaView(media: media.first, active: visible),
        ),
      );
    }

    // Lebih dari satu media: geser otomatis, hanya saat kartu terlihat di layar.
    return OnScreenBuilder(
      builder: (context, visible) =>
          _FeedMediaSlides(media: media, visible: visible),
    );
  }
}

/// Galeri multi-media yang bergeser otomatis setiap [_FeedMediaSlidesState._interval].
/// Timer berhenti saat kartu keluar layar atau sedang disentuh/digeser pengguna.
class _FeedMediaSlides extends StatefulWidget {
  final List<FeedMediaEntity> media;
  final bool visible;

  const _FeedMediaSlides({required this.media, required this.visible});

  @override
  State<_FeedMediaSlides> createState() => _FeedMediaSlidesState();
}

class _FeedMediaSlidesState extends State<_FeedMediaSlides> {
  static const _interval = Duration(seconds: 4);
  static const _animation = Duration(milliseconds: 500);

  final _pageController = PageController();
  Timer? _timer;
  int _page = 0;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _FeedMediaSlides oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      widget.visible ? _startTimer() : _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.media.length < 2) return;
    _timer = Timer.periodic(_interval, (_) => _next());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _next() {
    if (_userDragging || !_pageController.hasClients) return;
    final count = widget.media.length;
    final next = (_page + 1) % count;
    // Dari slide terakhir kembali ke awal langsung (tidak menggeser ulang semua slide).
    if (next == 0) {
      _pageController.jumpToPage(0);
    } else {
      _pageController.animateToPage(
        next,
        duration: _animation,
        curve: Curves.easeInOut,
      );
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDragging = true;
      _stopTimer();
    } else if (notification is ScrollEndNotification) {
      _userDragging = false;
      if (widget.visible) _startTimer();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _pageController,
              itemCount: media.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) =>
                  FeedMediaView(media: media[i], active: widget.visible),
            ),
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(whiteColor),
                ),
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
                        BoxShadow(
                          color: const Color(blackColor).withValues(alpha: 0.3),
                          blurRadius: 2,
                        ),
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

/// Memberi tahu [builder] apakah widget ini masih terlihat di viewport scroll terdekat.
/// Dipakai supaya video kartu yang sudah lewat layar di-pause, tidak berjalan bersamaan.
class OnScreenBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool visible) builder;

  const OnScreenBuilder({super.key, required this.builder});

  @override
  State<OnScreenBuilder> createState() => _OnScreenBuilderState();
}

class _OnScreenBuilderState extends State<OnScreenBuilder> {
  bool _visible = true;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final self = context.findRenderObject();
    final viewportObject = Scrollable.maybeOf(
      context,
    )?.context.findRenderObject();
    final box = self is RenderBox ? self : null;
    final viewport = viewportObject is RenderBox ? viewportObject : null;
    var visible = true;
    if (box != null &&
        viewport != null &&
        box.attached &&
        viewport.attached &&
        box.hasSize &&
        viewport.hasSize) {
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      visible = top + box.size.height > 0 && top < viewport.size.height;
    }
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _visible);
}
