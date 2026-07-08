import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/helpers/image_url.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/constants/colors.dart';

class DriveImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final VoidCallback? onTap;
  final FilterQuality filterQuality;
  
  
  final VoidCallback? onLoad;

  const DriveImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.onTap,
    this.filterQuality = FilterQuality.medium,
    this.onLoad,
  });

  @override
  State<DriveImage> createState() => _DriveImageState();
}

class _DriveImageState extends State<DriveImage> {
  bool _onLoadFired = false;

  void _fireOnLoad() {
    if (_onLoadFired) return;
    _onLoadFired = true;
    widget.onLoad?.call();
  }

  int _targetWidth() {
    final w = widget.width;
    final h = widget.height;
    final basis = (w != null && w.isFinite && w > 0)
        ? w
        : (h != null && h.isFinite && h > 0 ? h : null);
    if (basis == null) return 1000;
    
    return (basis * 2).round().clamp(1, 1600).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      convertDriveUrl(widget.url, targetWidth: _targetWidth()),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      
      
      
      
      cacheWidth: _targetWidth(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          _fireOnLoad();
          return child;
        }
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const ShimmerAttachmentItem(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _fireOnLoad();
        return widget.errorWidget ?? _defaultError();
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: image);
    }
    return image;
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Color(greyShade200),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 40, color: Color(greyShade500)),
    );
  }
}
