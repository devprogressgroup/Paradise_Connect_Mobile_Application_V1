import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:share_plus/share_plus.dart';

/// Bagikan kiriman feed dan kartu Wall of Fame (PWA mobile di iOS Safari & Android Chrome, serta native iOS & Android).
///
/// - Hanya media pertama yang dibagikan, bersama caption (teks ikut di pengiriman yang sama).
/// - Media diunduh HANYA saat tombol Bagikan ditekan, lalu disimpan di cache memori per key.
/// - Progres ditampilkan dengan SnackBar (standar Material), bukan bottom sheet.
/// - Setiap URL diubah menjadi XFile.fromData dengan nama dan MIME type eksplisit (.mp4 / video/mp4, .jpg / image/jpeg).
/// - Kalau Safari memblokir share otomatis (user gesture hilang karena unduhan lama), SnackBar menampilkan aksi "Kirim"
///   yang memanggil share dari cache memori.
class FeedShare {
  FeedShare._();

  static const _maxCachedPosts = 20;

  /// Cache memori: key (mis. 'post_12', 'fame_7') -> file yang sudah siap dibagikan. Tidak disimpan ke disk.
  static final Map<String, List<XFile>> _cache = {};

  /// Posisi global sebuah tombol (untuk sharePositionOrigin). Null kalau belum dirender.
  static Rect? rectOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// [origin] = posisi tombol Bagikan (sharePositionOrigin) supaya popover iPad/iPad Safari tidak error.
  static Future<void> sharePost(
    BuildContext context,
    FeedPostEntity post, {
    Rect? origin,
  }) async {
    final url = post.link?.url;
    final caption = post.plainText.trim();
    final poll = post.poll;
    final base = poll != null ? _pollText(caption, poll) : caption;
    final body = url == null ? base : '$base\n$url'.trim();
    // Caption opsional: kosong = null (tidak ada teks yang ikut).
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

    await shareMedia(
      context,
      cacheKey: 'post_${post.id}',
      filePrefix: 'kiriman_${post.id}',
      medias: medias,
      text: text,
      origin: origin,
    );
  }

  /// Teks poll untuk WA: pertanyaan dan daftar pilihan jawaban.
  /// Tanpa pilihan jawaban, penerima hanya melihat pertanyaannya.
  static String _pollText(String question, FeedPollEntity poll) {
    final buf = StringBuffer('📊 Polling: $question\n');
    for (final opt in poll.options) {
      buf.writeln('- ${opt.label}');
    }
    return buf.toString().trim();
  }

  /// Bagikan satu media (poster kartu, media kiriman) dengan caption. Dipakai juga oleh kartu Wall of Fame.
  /// Hanya media pertama yang dikirim.
  static Future<void> shareMedia(
    BuildContext context, {
    required String cacheKey,
    required String filePrefix,
    required List<FeedMediaEntity> medias,
    required String? text,
    Rect? origin,
  }) async {
    final first = medias.take(1).toList();
    final messenger = ScaffoldMessenger.maybeOf(context);

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan media untuk dibagikan...'),
        duration: Duration(minutes: 2),
      ),
    );

    List<XFile> files;
    try {
      files = await _filesFor(cacheKey, filePrefix, first);
    } catch (e) {
      debugPrint('FeedShare: gagal menyiapkan media: $e');
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Media gagal disiapkan untuk dibagikan.')),
      );
      return;
    }
    messenger?.hideCurrentSnackBar();

    await _shareFiles(
      files: files,
      text: text,
      origin: origin,
      messenger: messenger,
    );
  }

  /// Share file + caption. Kalau gagal (mis. Safari memblokir karena user gesture hilang), tampilkan SnackBar
  /// dengan aksi "Kirim" yang memanggil share lagi dari cache.
  static Future<void> _shareFiles({
    required List<XFile> files,
    required String? text,
    required Rect? origin,
    required ScaffoldMessengerState? messenger,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: text,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('FeedShare: share gagal: $e');
      messenger?.showSnackBar(
        SnackBar(
          content: const Text('Media siap dibagikan.'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Kirim',
            onPressed: () => _shareFiles(
              files: files,
              text: text,
              origin: origin,
              messenger: messenger,
            ),
          ),
        ),
      );
    }
  }

  /// File siap bagikan untuk satu key. Pakai cache kalau sudah pernah diunduh.
  static Future<List<XFile>> _filesFor(
    String cacheKey,
    String filePrefix,
    List<FeedMediaEntity> medias,
  ) async {
    final cached = _cache[cacheKey];
    if (cached != null && cached.length == medias.length) return cached;

    final files = await Future.wait([
      for (var i = 0; i < medias.length; i++) _toXFile(filePrefix, medias[i], i),
    ]);

    if (_cache.length >= _maxCachedPosts && !_cache.containsKey(cacheKey)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = files;
    return files;
  }

  /// Mengubah satu media (URL atau bytes lokal) menjadi XFile dengan nama dan MIME type eksplisit.
  static Future<XFile> _toXFile(String filePrefix, FeedMediaEntity media, int index) async {
    final isVideo = media.isVideo;
    final ext = isVideo ? '.mp4' : '.jpg';
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    final name = '${filePrefix}_${index + 1}$ext';

    Uint8List bytes;
    final local = media.bytes;
    if (local != null) {
      bytes = local;
    } else {
      final url = media.url;
      if (url == null || url.isEmpty) {
        throw StateError('URL media kosong');
      }
      final headers = _isSigned(url)
          ? const <String, String>{}
          : AuthTokenCache.getAuthHeadersFor(url);
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
