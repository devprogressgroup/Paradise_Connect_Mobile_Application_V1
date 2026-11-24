import 'dart:io';

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:video_player/video_player.dart';

/// Thumbnail video lokal (baru dipilih di form, belum diunggah): menampilkan frame pertama
/// dari file dengan ikon play di tengah. Kalau gagal dibaca, tampil [fallback].
class FeedLocalVideoThumb extends StatefulWidget {
  final String path;
  final Widget fallback;

  /// true = tile kecil (grid media form): ikon play dan penanda video ikut mengecil.
  final bool compact;

  const FeedLocalVideoThumb({
    super.key,
    required this.path,
    required this.fallback,
    this.compact = false,
  });

  @override
  State<FeedLocalVideoThumb> createState() => _FeedLocalVideoThumbState();
}

class _FeedLocalVideoThumbState extends State<FeedLocalVideoThumb> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = VideoPlayerController.file(File(widget.path));
      _controller = controller;
      await controller.initialize();
      await controller.setVolume(0);
      // Diam di frame pertama supaya gambar pertama video terlihat sebagai thumbnail.
      await controller.seekTo(Duration.zero);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      debugPrint('FeedLocalVideoThumb gagal membaca ${widget.path}: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || !_ready || controller == null) return widget.fallback;

    final size = controller.value.size;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        // Center: di dalam Stack dengan StackFit.expand, anak tanpa Positioned dipaksa
        // memenuhi seluruh area, sehingga width/height Container diabaikan.
        Center(
          child: Container(
            // padding: EdgeInsets.all(widget.compact ? 3 : 8),
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: widget.compact ? 16 : 26,
            ),
          ),
        ),
        if (!widget.compact)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(blackColor).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
