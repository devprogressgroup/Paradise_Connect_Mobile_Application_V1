import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/helpers/image_url.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';

class DriveImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final VoidCallback? onTap;
  final FilterQuality filterQuality;

  const DriveImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.onTap,
    this.filterQuality = FilterQuality.medium,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      convertDriveUrl(url),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const ShimmerAttachmentItem(),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? _defaultError(),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: image);
    }
    return image;
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }
}
