// Web: pakai Image.network bawaan Flutter (bukan HtmlElementView manual).
// HtmlElementView/<img> manual sebelumnya dipakai buat menghindari CORS, tapi
// platform view itu ternyata bisa lolos dari ClipRRect/Stack Flutter di
// WebKit lama (iOS 15) — gambar bisa nutupin header/bottom nav. Image.network
// dirender lewat canvas Flutter sendiri, otomatis ikut aturan clip/layout,
// tidak bisa lolos ke luar batasnya.
import 'package:flutter/material.dart';

class DriveImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final VoidCallback? onTap;
  final FilterQuality filterQuality;
  // Dipanggil sekali saat gambar selesai dimuat ATAU gagal — dipakai carousel
  // untuk memuat gambar satu-satu berurutan, bukan sekaligus semua.
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

  // onLoad harus persis sekali per gambar (sukses ATAU gagal) — carousel di
  // pemanggil pakai ini sebagai sinyal "lanjut ke gambar berikutnya".
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
    // x2 buat layar retina, dibatasi biar tidak minta lebih dari yang perlu.
    return (basis * 2).round().clamp(1, 1600).toInt();
  }

  String _toCdnUrl(String url) {
    try {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match == null) return url;
      final id = match.group(1);
      final baseUrl = 'https://lh3.googleusercontent.com/d/$id';

      // Minta thumbnail SEUKURAN yang benar-benar ditampilkan (x2 buat layar
      // retina), bukan foto original — foto HP modern bisa 3000x4000+ piksel;
      // decode ukuran itu cuma buat ditampilkan di kotak 200x200 boros memori
      // banget, apalagi di device RAM kecil (mis. iPhone lama). lh3.googleusercontent.com
      // mendukung suffix "=w{width}-h{height}" buat resize di sisi server.
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
      // Pengaman tambahan: walau sudah minta thumbnail kecil ke server, ini
      // maksa Flutter sendiri DECODE di ukuran kecil itu juga.
      cacheWidth: _targetPixelSize(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          _fireOnLoad();
          return child;
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
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
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }
}
