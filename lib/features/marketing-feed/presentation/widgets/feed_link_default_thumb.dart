import 'package:flutter/material.dart';

/// Thumbnail bawaan untuk link yang tidak punya gambar (IG, FB, TikTok, Web).
/// Background dan logo mengikuti warna khas tiap platform. Ganti [_InstagramMark] dkk. dengan
/// logo resmi (aset PNG/SVG) kalau sudah tersedia.
class FeedLinkDefaultThumb extends StatelessWidget {
  final String platform;

  /// true = ukuran kecil (daftar kiriman/draft), logo tanpa label.
  final bool compact;

  const FeedLinkDefaultThumb({
    super.key,
    required this.platform,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(platform);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: style.gradient),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: compact ? -12 : -24,
            top: compact ? -12 : -24,
            child: Container(
              width: compact ? 40 : 110,
              height: compact ? 40 : 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              style.logo(compact ? 22 : 44),
              if (!compact) ...[
                const SizedBox(height: 10),
                Text(
                  style.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static _PlatformStyle _styleFor(String platform) => switch (platform) {
        'instagram' => _PlatformStyle(
            label: 'Instagram',
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            logo: (size) => _InstagramMark(size: size),
          ),
        'facebook' => _PlatformStyle(
            label: 'Facebook',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1877F2), Color(0xFF0C4FB8)],
            ),
            logo: (size) => _FacebookMark(size: size),
          ),
        'tiktok' => _PlatformStyle(
            label: 'TikTok',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
            ),
            logo: (size) => _TikTokMark(size: size),
          ),
        _ => _PlatformStyle(
            label: 'Website',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
            ),
            logo: (size) => Icon(Icons.language, size: size, color: Colors.white),
          ),
      };
}

class _PlatformStyle {
  final String label;
  final Gradient gradient;
  final Widget Function(double size) logo;

  const _PlatformStyle({
    required this.label,
    required this.gradient,
    required this.logo,
  });
}

/// Kamera khas Instagram: kotak membulat, lingkaran lensa, dan titik kecil.
class _InstagramMark extends StatelessWidget {
  final double size;

  const _InstagramMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final stroke = size * 0.1;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: stroke),
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
          ),
          Container(
            width: size * 0.45,
            height: size * 0.45,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: stroke),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            right: size * 0.16,
            top: size * 0.16,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Huruf "f" tebal di lingkaran putih, mirip logo Facebook.
class _FacebookMark extends StatelessWidget {
  final double size;

  const _FacebookMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(
        'f',
        style: TextStyle(
          color: const Color(0xFF1877F2),
          fontSize: size * 0.8,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Not musik dengan bayangan cyan dan merah, khas logo TikTok.
class _TikTokMark extends StatelessWidget {
  final double size;

  const _TikTokMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-size * 0.06, -size * 0.04),
          child: Icon(Icons.music_note_rounded, size: size, color: const Color(0xFF25F4EE)),
        ),
        Transform.translate(
          offset: Offset(size * 0.06, size * 0.04),
          child: Icon(Icons.music_note_rounded, size: size, color: const Color(0xFFFE2C55)),
        ),
        Icon(Icons.music_note_rounded, size: size, color: Colors.white),
      ],
    );
  }
}
