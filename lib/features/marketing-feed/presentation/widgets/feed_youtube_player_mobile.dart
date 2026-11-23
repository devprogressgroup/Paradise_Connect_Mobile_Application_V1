import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Pemutar YouTube inline di kartu feed, memakai package youtube_player_iframe.
/// Autoplay saat kartu terlihat, di-pause saat keluar layar, dan diputar lagi saat kembali terlihat.
/// Kalau embed dimatikan pemilik video (error 150/152/153), tampil poster dengan tombol buka di YouTube.
class FeedYoutubePlayer extends StatefulWidget {
  final String videoId;

  /// false = kartu keluar layar, video di-pause. Saat kembali true, diputar lagi.
  final bool visible;

  /// Tampilan sebelum video mulai (thumbnail), tampil di belakang player.
  final Widget poster;

  const FeedYoutubePlayer({
    super.key,
    required this.videoId,
    required this.visible,
    required this.poster,
  });

  @override
  State<FeedYoutubePlayer> createState() => _FeedYoutubePlayerState();
}

class _FeedYoutubePlayerState extends State<FeedYoutubePlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;

  /// Embed gagal (dimatikan pemilik video / jaringan): tampilkan poster dengan tombol YouTube.
  bool _failed = false;

  /// Video mulai tanpa suara (aturan autoplay); pengguna menyalakan suara lewat tombol speaker.
  bool _muted = true;

  ModalRoute<dynamic>? _route;

  /// Ada dialog/sheet di atas kartu. WebView pemutar tampil di atas widget Flutter lain,
  /// jadi saat tertutup WebView diganti poster agar sentuhan pada dialog tidak masuk ke player.
  bool _covered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _route)) return;
    _route?.secondaryAnimation?.removeListener(_onCoverChanged);
    _route = route;
    route?.secondaryAnimation?.addListener(_onCoverChanged);
    _covered = (route?.secondaryAnimation?.value ?? 0) > 0;
  }

  void _onCoverChanged() {
    final covered = (_route?.secondaryAnimation?.value ?? 0) > 0;
    if (covered == _covered) return;
    _covered = covered;
    if (covered) {
      _controller?.pauseVideo();
    } else if (widget.visible) {
      _controller?.playVideo();
    }
    if (mounted) setState(() {});
  }

  void _toggleMute() {
    if (_muted) {
      _controller?.unMute();
    } else {
      _controller?.mute();
    }
    setState(() => _muted = !_muted);
  }

  @override
  void initState() {
    super.initState();
    if (widget.visible) _createController();
  }

  void _createController() {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      // Autoplay wajib tanpa suara di WebView; suara dinyalakan lewat tombol speaker.
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: true,
      ),
    );
    _subscription = controller.listen(
      (value) {
        if (value.hasError && mounted && !_failed) {
          debugPrint(
            'FeedYoutubePlayer error ${widget.videoId}: ${value.error}',
          );
          setState(() => _failed = true);
        }
      },
    );
    _controller = controller;
  }

  @override
  void didUpdateWidget(covariant FeedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      if (_controller == null) {
        setState(_createController);
      } else {
        _controller!.playVideo();
      }
    } else {
      _controller?.pauseVideo();
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeListener(_onCoverChanged);
    _subscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _openInYoutube() {
    launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      // Embed tidak bisa diputar di sini: tampilkan poster dan ajak buka di aplikasi YouTube.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openInYoutube,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.poster,
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Video tidak bisa diputar di sini. Tonton langsung di YouTube.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _openInYoutube,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              'Tonton di YouTube',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || _covered) return widget.poster;

    // Tombol suara ditaruh di bawah video (bukan di atas), karena WebView pemutar
    // tampil di atas widget Flutter lain dan akan menutupi tombol yang ada di dalam area video.
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.poster,
              YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: _toggleMute,
            visualDensity: VisualDensity.compact,
            tooltip: _muted ? 'Nyalakan suara' : 'Matikan suara',
            icon: Icon(
              _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
