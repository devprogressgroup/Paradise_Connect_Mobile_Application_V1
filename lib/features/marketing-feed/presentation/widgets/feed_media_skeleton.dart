import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Placeholder saat foto/video feed sedang dimuat: kotak abu-abu dengan kilau shimmer yang bergerak,
/// dan ikon kecil di tengah. Dipakai sebagai pengganti spinner supaya kartu tidak terlihat kosong.
class FeedMediaSkeleton extends StatefulWidget {
  final bool isVideo;

  const FeedMediaSkeleton({super.key, this.isVideo = false});

  @override
  State<FeedMediaSkeleton> createState() => _FeedMediaSkeletonState();
}

class _FeedMediaSkeletonState extends State<FeedMediaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Kilau bergerak dari kiri ke kanan, lalu mengulang.
          final v = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-2.2 + 3.4 * v, 0),
                end: Alignment(-0.2 + 3.4 * v, 0),
                colors: const [
                  Color(grey10Color),
                  Color(whiteColor),
                  Color(grey10Color),
                ],
                stops: const [0.2, 0.5, 0.8],
              ),
            ),
            child: Center(
              child: Icon(
                widget.isVideo
                    ? Icons.play_circle_outline_rounded
                    : Icons.image_outlined,
                size: 28,
                color: const Color(grey4Color).withValues(alpha: 0.7),
              ),
            ),
          );
        },
      ),
    );
  }
}
