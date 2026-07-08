
import 'package:flutter/material.dart';
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
  State<DriveImage> createState() => _DriveImageWebState();
}

class _DriveImageWebState extends State<DriveImage> {
  bool _onLoadFired = false;



  void _fireOnLoad() {
    if (_onLoadFired) return;
    _onLoadFired = true;
    widget.onLoad?.call();
  }

  int? _targetPixelSize() {
    final w = widget.width;
    final h = widget.height;
    final basis = (w != null && w.isFinite && w > 0)
        ? w
        : (h != null && h.isFinite && h > 0 ? h : null);
    if (basis == null) return null;

    return (basis * 2).round().clamp(1, 1600).toInt();
  }

  String _toCdnUrl(String url) {
    try {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match == null) return url;
      final id = match.group(1);
      final baseUrl = 'https://lh3.googleusercontent.com/d/$id';






      final size = _targetPixelSize();
      if (size == null) return baseUrl;
      return '$baseUrl=w$size-h$size';
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      _toCdnUrl(widget.url),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: widget.filterQuality,


      cacheWidth: _targetPixelSize(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          _fireOnLoad();
          return child;
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Color(greyShade200),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _fireOnLoad();
        return widget.errorWidget ?? _defaultError();
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      );
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
