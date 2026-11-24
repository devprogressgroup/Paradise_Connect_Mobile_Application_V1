import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:share_plus/share_plus.dart';

/// Bagikan kiriman feed (PWA mobile di iOS Safari & Android Chrome, serta native iOS & Android).
///
/// - Media (carousel campuran video dan gambar) diunduh HANYA saat tombol Bagikan ditekan, lalu disimpan di cache
///   memori per postId. Feed pertama kali dimuat tidak mengunduh apa pun.
/// - Setiap URL diubah menjadi XFile.fromData dengan nama dan MIME type eksplisit (.mp4 / video/mp4, .jpg / image/jpeg).
/// - Caption opsional: kalau kosong atau null, yang dikirim hanya files (text: null).
/// - Kalau Safari memblokir share otomatis (user gesture hilang karena unduhan lama), bottom sheet menampilkan
///   tombol "Kirim Sekarang" yang memanggil share dari cache memori.
class FeedShare {
  FeedShare._();

  static const _maxFiles = 10;
  static const _maxCachedPosts = 20;

  /// Cache memori: postId -> file yang sudah siap dibagikan. Tidak disimpan ke disk.
  static final Map<int, List<XFile>> _cache = {};

  /// Buka bottom sheet: unduh media (atau pakai cache), lalu panggil share.
  /// [origin] = posisi tombol Bagikan (sharePositionOrigin) supaya popover iPad/iPad Safari tidak error.
  static Future<void> sharePost(
    BuildContext context,
    FeedPostEntity post, {
    Rect? origin,
  }) async {
    final url = post.link?.url;
    final caption = post.plainText.trim();
    final body = url == null ? caption : '$caption\n$url'.trim();
    // Caption opsional: kosong = null (kirim files saja).
    final text = body.isEmpty ? null : body;

    final medias = post.media.isNotEmpty
        ? post.media
        : [if (post.poll?.image != null) post.poll!.image!];

    // Tanpa media: cukup bagikan teks (atau kalimat pendek kalau tidak ada apa-apa).
    if (medias.isEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          text: text ?? 'Dibagikan dari Marketing Feed',
          sharePositionOrigin: origin,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      builder: (_) => _FeedShareSheet(
        post: post,
        medias: medias.take(_maxFiles).toList(),
        text: text,
        origin: origin,
      ),
    );
  }

  /// File siap bagikan untuk satu kiriman. Pakai cache kalau sudah pernah diunduh.
  static Future<List<XFile>> filesFor(
    FeedPostEntity post,
    List<FeedMediaEntity> medias,
  ) async {
    final cached = _cache[post.id];
    if (cached != null && cached.length == medias.length) return cached;

    final files = await Future.wait([
      for (var i = 0; i < medias.length; i++) _toXFile(post.id, medias[i], i),
    ]);

    if (_cache.length >= _maxCachedPosts) {
      _cache.remove(_cache.keys.first);
    }
    _cache[post.id] = files;
    return files;
  }

  /// Mengubah satu media (URL atau bytes lokal) menjadi XFile dengan nama dan MIME type eksplisit.
  static Future<XFile> _toXFile(int postId, FeedMediaEntity media, int index) async {
    final isVideo = media.isVideo;
    final ext = isVideo ? '.mp4' : '.jpg';
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    final name = 'kiriman_${postId}_${index + 1}$ext';

    Uint8List bytes;
    final local = media.bytes;
    if (local != null) {
      bytes = local;
    } else {
      final url = media.url;
      if (url == null || url.isEmpty) {
        throw StateError('URL media kosong');
      }
      final headers = _isSigned(url) ? const <String, String>{} : AuthTokenCache.getAuthHeadersFor(url);
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode != 200) {
        throw StateError('Gagal mengunduh media (HTTP ${response.statusCode})');
      }
      bytes = response.bodyBytes;
    }

    return XFile.fromData(bytes, name: name, mimeType: mime);
  }

  /// URL yang sudah bertanda tangan (signature) tidak perlu header Authorization.
  static bool _isSigned(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.queryParameters.keys.any((k) {
      final key = k.toLowerCase();
      return key.contains('signature') || key == 'sig' || key.startsWith('x-amz-');
    });
  }
}

/// Bottom sheet: loading saat unduh, lalu share otomatis. Kalau gagal (mis. Safari memblokir), tampilkan tombol.
class _FeedShareSheet extends StatefulWidget {
  final FeedPostEntity post;
  final List<FeedMediaEntity> medias;
  final String? text;
  final Rect? origin;

  const _FeedShareSheet({
    required this.post,
    required this.medias,
    required this.text,
    required this.origin,
  });

  @override
  State<_FeedShareSheet> createState() => _FeedShareSheetState();
}

class _FeedShareSheetState extends State<_FeedShareSheet> {
  List<XFile>? _files;
  bool _needsTap = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final files = await FeedShare.filesFor(widget.post, widget.medias);
      if (!mounted) return;
      _files = files;
      await _shareFiles(auto: true);
    } catch (e) {
      debugPrint('FeedShare: gagal menyiapkan media: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Share dengan file. [auto] = dipanggil otomatis setelah unduhan; kalau gagal, minta ketukan user.
  Future<void> _shareFiles({required bool auto}) async {
    final files = _files;
    if (files == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: widget.text,
          sharePositionOrigin: widget.origin,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('FeedShare: share ${auto ? 'otomatis' : 'manual'} gagal: $e');
      // Tidak ada user gesture saat auto: minta ketukan. Saat ketukan tetap gagal: fallback ke teks saja.
      if (!mounted) return;
      if (auto) {
        setState(() => _needsTap = true);
      } else {
        await _shareTextOnly();
      }
    }
  }

  /// Fallback kalau browser/OS tidak mendukung share file: bagikan caption/link saja.
  Future<void> _shareTextOnly() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: widget.text ?? 'Dibagikan dari Marketing Feed',
          sharePositionOrigin: widget.origin,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('FeedShare: fallback teks juga gagal: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + 24;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_failed) ...[
              const Text('Media tidak bisa dibagikan.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ] else if (_needsTap) ...[
              const Text('Media siap dibagikan.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _shareFiles(auto: false),
                child: const Text('Kirim Sekarang'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Menyiapkan media untuk dibagikan...'),
            ],
          ],
        ),
      ),
    );
  }
}
