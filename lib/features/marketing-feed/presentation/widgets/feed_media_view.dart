import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Satu foto/video, mengisi penuh kotaknya. File lokal (baru dipilih) ditampilkan dari bytes;
/// media tanpa url (data dummy) atau video tampil sebagai placeholder berlabel.
class FeedMediaView extends StatelessWidget {
  final FeedMediaEntity media;
  final bool compact;

  const FeedMediaView({super.key, required this.media, this.compact = false});

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
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) => progress == null ? child : _placeholder(loading: true),
        errorBuilder: (_, __, ___) => _placeholder(),
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

/// Galeri media post: satu media tampil persegi, lebih dari satu bisa di-swipe dengan penanda
/// "1/4" dan titik halaman.
class FeedMediaCarousel extends StatefulWidget {
  final List<FeedMediaEntity> media;

  const FeedMediaCarousel({super.key, required this.media});

  @override
  State<FeedMediaCarousel> createState() => _FeedMediaCarouselState();
}

class _FeedMediaCarouselState extends State<FeedMediaCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.length == 1) {
      return AspectRatio(aspectRatio: 1, child: FeedMediaView(media: media.first));
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
