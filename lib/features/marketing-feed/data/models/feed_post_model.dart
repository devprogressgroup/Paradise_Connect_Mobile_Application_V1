import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_comment_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

class FeedMediaModel extends FeedMediaEntity {
  const FeedMediaModel({
    super.url,
    super.label,
    super.isVideo,
    super.bytes,
    super.fileName,
  });

  factory FeedMediaModel.fromJson(Map<String, dynamic> json) {
    return FeedMediaModel(
      url: json['url'] as String?,
      label: json['label'] as String?,
      isVideo: json['type'] == 'video',
    );
  }
}

class FeedInteractionSettingsModel extends FeedInteractionSettings {
  const FeedInteractionSettingsModel({
    super.allowLike,
    super.allowDislike,
    super.allowComment,
    super.allowReply,
    super.allowShare,
  });

  factory FeedInteractionSettingsModel.fromJson(Map<String, dynamic> json) {
    return FeedInteractionSettingsModel(
      allowLike: json['allow_like'] != false,
      allowDislike: json['allow_dislike'] != false,
      allowComment: json['allow_comment'] != false,
      allowReply: json['allow_reply'] != false,
      allowShare: json['allow_share'] != false,
    );
  }
}

class FeedPollModel extends FeedPollEntity {
  const FeedPollModel({
    required super.options,
    required super.votes,
    super.totalVoters,
    super.isMultiple,
    super.image,
    super.myVotes,
  });

  factory FeedPollModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    return FeedPollModel(
      options: (json['options'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      votes: (json['votes'] as List<dynamic>? ?? const []).map((e) => (e as num).toInt()).toList(),
      totalVoters: json['total_voters'] as int? ?? 0,
      isMultiple: json['is_multiple'] == true,
      image: image == null ? null : FeedMediaModel.fromJson(image),
      myVotes: (json['my_votes'] as List<dynamic>? ?? const []).map((e) => (e as num).toInt()).toList(),
    );
  }
}

class FeedLinkModel extends FeedLinkEntity {
  const FeedLinkModel({
    required super.url,
    required super.source,
    super.sourceLabel,
    required super.title,
    super.description,
  });

  factory FeedLinkModel.fromJson(Map<String, dynamic> json) {
    return FeedLinkModel(
      url: json['url'] as String? ?? '',
      source: json['source'] as String? ?? 'web',
      sourceLabel: json['source_label'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class FeedPostModel extends FeedPostEntity {
  const FeedPostModel({
    required super.id,
    required super.type,
    required super.status,
    required super.author,
    super.text,
    super.label,
    super.project,
    super.media,
    super.poll,
    super.link,
    super.settings,
    required super.publishAt,
    super.likeCount,
    super.dislikeCount,
    super.myReaction,
    super.commentCount,
    super.latestComment,
    super.rejectReason,
    super.isMine,
    super.fromAdminWeb,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    final poll = json['poll'] as Map<String, dynamic>?;
    final link = json['link'] as Map<String, dynamic>?;
    final settings = json['settings'] as Map<String, dynamic>?;
    final latestComment = json['latest_comment'] as Map<String, dynamic>?;
    return FeedPostModel(
      id: json['id'] as int,
      type: FeedPostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedPostType.post,
      ),
      status: FeedPostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FeedPostStatus.published,
      ),
      author: FeedAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? const {}),
      text: json['text'] as String? ?? '',
      label: json['label'] as String?,
      project: json['project'] as String?,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((e) => FeedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      poll: poll == null ? null : FeedPollModel.fromJson(poll),
      link: link == null ? null : FeedLinkModel.fromJson(link),
      settings: settings == null
          ? const FeedInteractionSettingsModel()
          : FeedInteractionSettingsModel.fromJson(settings),
      publishAt: DateTime.tryParse(json['publish_at'] as String? ?? '') ?? DateTime.now(),
      likeCount: json['like_count'] as int? ?? 0,
      dislikeCount: json['dislike_count'] as int? ?? 0,
      myReaction: json['my_reaction'] == 'like'
          ? FeedReaction.like
          : json['my_reaction'] == 'dislike'
              ? FeedReaction.dislike
              : FeedReaction.none,
      commentCount: json['comment_count'] as int? ?? 0,
      latestComment: latestComment == null ? null : FeedCommentModel.fromJson(latestComment),
      rejectReason: json['reject_reason'] as String?,
      isMine: json['is_mine'] == true,
      fromAdminWeb: json['source'] == 'admin',
    );
  }
}

class FeedPageModel extends FeedPageEntity {
  const FeedPageModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
  });

  factory FeedPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    return FeedPageModel(
      items: data.map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }
}
