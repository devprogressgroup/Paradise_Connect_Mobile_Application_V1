// Web-only: pakai HTML <img> element untuk bypass CORS restriction.
// HtmlElementView intercept semua pointer event — gunakan transparent overlay
// GestureDetector di atas HtmlElementView agar onTap bisa diterima Flutter.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class DriveImage extends StatefulWidget {
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
  State<DriveImage> createState() => _DriveImageWebState();
}

class _DriveImageWebState extends State<DriveImage> {
  static int _counter = 0;
  late final String _viewId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewId = 'drive-img-$_counter';

    final img = html.ImageElement()
      ..src = _toCdnUrl(widget.url)
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _fitToCss(widget.fit)
      ..style.display = 'block'
      // pointer-events: none agar overlay GestureDetector yang handle tap
      ..style.pointerEvents = 'none';

    img.onError.listen((_) {
      if (mounted) setState(() => _hasError = true);
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => img);
  }

  String _toCdnUrl(String url) {
    try {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match != null) {
        return 'https://lh3.googleusercontent.com/d/${match.group(1)}';
      }
      return url;
    } catch (_) {
      return url;
    }
  }

  String _fitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:   return 'cover';
      case BoxFit.contain: return 'contain';
      case BoxFit.fill:    return 'fill';
      default:             return 'cover';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      final fallback = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
      if (widget.onTap != null) {
        return GestureDetector(onTap: widget.onTap, child: fallback);
      }
      return fallback;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(child: HtmlElementView(viewType: _viewId)),
          // Overlay transparan untuk menangkap tap ke Flutter
          if (widget.onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}
