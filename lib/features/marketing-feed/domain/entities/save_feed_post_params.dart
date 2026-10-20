import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Body buat/edit post & poll dari form moderator.
class SaveFeedPostParams {
  /// null = buat baru.
  final int? postId;

  /// [FeedPostType.post] atau [FeedPostType.poll] — link sosmed hanya dibuat dari Admin Web.
  final FeedPostType type;

  /// Caption post, atau pertanyaan poll.
  final String text;
  final List<FeedMediaEntity> media;
  final List<String> pollOptions;
  final bool pollMultiple;
  final FeedMediaEntity? pollImage;
  final FeedInteractionSettings settings;

  /// null = langsung tayang.
  final DateTime? scheduledAt;
  final bool asDraft;

  const SaveFeedPostParams({
    this.postId,
    required this.type,
    required this.text,
    this.media = const [],
    this.pollOptions = const [],
    this.pollMultiple = false,
    this.pollImage,
    this.settings = const FeedInteractionSettings(),
    this.scheduledAt,
    this.asDraft = false,
  });
}

/// Body kiriman "Bagikan Momen" dari sales — masuk antrean review moderator dulu.
class ShareFeedMomentParams {
  final String text;
  final List<FeedMediaEntity> media;

  const ShareFeedMomentParams({required this.text, this.media = const []});
}
