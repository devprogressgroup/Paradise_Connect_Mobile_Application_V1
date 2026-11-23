import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Versi web: iframe YouTube langsung (WebView tidak tersedia di web). Autoplay memakai muted,
/// yang diizinkan browser. Play/pause lewat postMessage ke YouTube IFrame API.
class FeedYoutubePlayer extends StatefulWidget {
  final String videoId;

  /// false = kartu keluar layar, video di-pause. Saat kembali true, diputar lagi.
  final bool visible;

  /// Tampilan sebelum video mulai (thumbnail), tampil di belakang iframe.
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
  static int _viewCounter = 0;

  late final String _viewId;
  late final html.IFrameElement _iframe;
  bool _playing = true;

  /// Autoplay wajib muted (kebijakan browser), jadi video mulai tanpa suara.
  /// Pengguna bisa menyalakan suara lewat tombol speaker (sudah ada interaksi tap).
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _viewId = 'feed-youtube-${_viewCounter++}';
    _iframe = html.IFrameElement()
      ..src = _embedUrl(widget.videoId)
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'autoplay; encrypted-media; picture-in-picture'
      ..allowFullscreen = true
      // Iframe adalah elemen DOM asli di atas canvas Flutter. Tanpa ini, scroll mouse dan
      // klik di area video ditangkap iframe (scroll feed macet, klik dialog jatuh ke YouTube).
      // Interaksi tetap lewat overlay Flutter (tap untuk play/pause, tombol suara).
      ..style.pointerEvents = 'none';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => _iframe);
  }

  @override
  void didUpdateWidget(covariant FeedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _command('playVideo');
      setState(() => _playing = true);
    } else {
      _command('pauseVideo');
      setState(() => _playing = false);
    }
  }

  static String _embedUrl(String videoId) =>
      'https://www.youtube.com/embed/$videoId'
      '?autoplay=1&mute=1&playsinline=1&enablejsapi=1&controls=0&rel=0&modestbranding=1';

  void _command(String func) {
    _iframe.contentWindow?.postMessage(
      '{"event":"command","func":"$func","args":""}',
      '*',
    );
  }

  void _togglePlay() {
    _command(_playing ? 'pauseVideo' : 'playVideo');
    setState(() => _playing = !_playing);
  }

  void _toggleMute() {
    if (_muted) {
      _command('unMute');
      _iframe.contentWindow?.postMessage(
        '{"event":"command","func":"setVolume","args":[100]}',
        '*',
      );
    } else {
      _command('mute');
    }
    setState(() => _muted = !_muted);
  }

  @override
  void dispose() {
    _iframe.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.poster,
        HtmlElementView(viewType: _viewId),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlay,
          child: Center(
            child: AnimatedOpacity(
              opacity: _playing ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
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
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMute,
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
    );
  }
}
