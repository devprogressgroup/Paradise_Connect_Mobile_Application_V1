import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Body kiriman sales (POST /marketing-feed/submit). Ditinjau moderator atau langsung tayang sesuai permission SkipReview.
class ShareFeedMomentParams {
  /// post (caption + media, boleh tanpa caption), poll (pertanyaan + opsi), atau link (URL + detail).
  final FeedPostType type;

  /// Caption untuk post, atau pertanyaan untuk poll. Tidak dipakai untuk link.
  final String text;
  final List<FeedMediaEntity> media;

  /// Poll: pilihan jawaban dan boleh pilih lebih dari satu.
  final List<String> pollOptions;
  final bool pollMultiple;

  /// Link: URL dan detail (platform dikenali server dari URL).
  final String linkUrl;
  final String linkChannel;
  final String linkTitle;
  final String linkDescription;

  /// null = ikut township sales (atau semua kalau bukan sales).
  final int? townshipId;
  final FeedInteractionSettings settings;

  /// null = tayang sekarang. Jam dinding WIB.
  final DateTime? scheduledAt;

  /// Simpan sebagai draft (tidak dikirim ke review / tayang).
  final bool asDraft;

  /// Progress upload multipart (byte terkirim, total byte).
  final void Function(int sent, int total)? onProgress;

  const ShareFeedMomentParams({
    this.type = FeedPostType.post,
    required this.text,
    this.media = const [],
    this.pollOptions = const [],
    this.pollMultiple = false,
    this.linkUrl = '',
    this.linkChannel = '',
    this.linkTitle = '',
    this.linkDescription = '',
    this.townshipId,
    this.settings = const FeedInteractionSettings(),
    this.scheduledAt,
    this.asDraft = false,
    this.onProgress,
  });

  ShareFeedMomentParams copyWith({
    void Function(int sent, int total)? onProgress,
  }) {
    return ShareFeedMomentParams(
      type: type,
      text: text,
      media: media,
      pollOptions: pollOptions,
      pollMultiple: pollMultiple,
      linkUrl: linkUrl,
      linkChannel: linkChannel,
      linkTitle: linkTitle,
      linkDescription: linkDescription,
      townshipId: townshipId,
      settings: settings,
      scheduledAt: scheduledAt,
      asDraft: asDraft,
      onProgress: onProgress ?? this.onProgress,
    );
  }
}

/// Body buat/edit post, poll, atau link dari form moderator (POST /marketing-feed/moderator/posts[/id]).
class SaveFeedPostParams {
  /// null = buat baru.
  final int? postId;
  final FeedPostType type;

  /// Caption post, atau pertanyaan poll. Tidak dipakai untuk link.
  final String text;

  /// Carousel post (maks 10), gambar pertanyaan poll / thumbnail link (maks 1). Media lama (punya `id`)
  /// dipertahankan, media baru (punya `bytes`/`filePath`) di-upload.
  final List<FeedMediaEntity> media;
  final List<String> pollOptions;
  final bool pollMultiple;

  /// Link: `youtube` | `web`.
  final String linkPlatform;
  final String linkUrl;
  final String linkChannel;
  final String linkTitle;
  final String linkDescription;

  /// null = semua township.
  final int? townshipId;
  final FeedInteractionSettings settings;

  /// null = langsung tayang. Jam dinding WIB (konvensi AppTime.now).
  final DateTime? scheduledAt;
  final bool asDraft;

  /// Progress upload multipart (byte terkirim, total byte).
  final void Function(int sent, int total)? onProgress;

  const SaveFeedPostParams({
    this.postId,
    required this.type,
    this.text = '',
    this.media = const [],
    this.pollOptions = const [],
    this.pollMultiple = false,
    this.linkPlatform = 'youtube',
    this.linkUrl = '',
    this.linkChannel = '',
    this.linkTitle = '',
    this.linkDescription = '',
    this.townshipId,
    this.settings = const FeedInteractionSettings(),
    this.scheduledAt,
    this.asDraft = false,
    this.onProgress,
  });

  SaveFeedPostParams copyWith({
    void Function(int sent, int total)? onProgress,
  }) {
    return SaveFeedPostParams(
      postId: postId,
      type: type,
      text: text,
      media: media,
      pollOptions: pollOptions,
      pollMultiple: pollMultiple,
      linkPlatform: linkPlatform,
      linkUrl: linkUrl,
      linkChannel: linkChannel,
      linkTitle: linkTitle,
      linkDescription: linkDescription,
      townshipId: townshipId,
      settings: settings,
      scheduledAt: scheduledAt,
      asDraft: asDraft,
      onProgress: onProgress ?? this.onProgress,
    );
  }
}
