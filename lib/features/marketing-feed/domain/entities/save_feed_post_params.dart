import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Body kiriman "Bagikan Momen" dari sales — masuk antrean review moderator dulu.
class ShareFeedMomentParams {
  final String text;
  final List<FeedMediaEntity> media;
  final int? townshipId;

  /// Progress upload multipart (byte terkirim, total byte).
  final void Function(int sent, int total)? onProgress;

  const ShareFeedMomentParams({
    required this.text,
    this.media = const [],
    this.townshipId,
    this.onProgress,
  });

  ShareFeedMomentParams copyWith({void Function(int sent, int total)? onProgress}) {
    return ShareFeedMomentParams(
      text: text,
      media: media,
      townshipId: townshipId,
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

  SaveFeedPostParams copyWith({void Function(int sent, int total)? onProgress}) {
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
