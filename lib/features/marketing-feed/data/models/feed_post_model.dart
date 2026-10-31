import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_comment_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

class FeedTownshipModel extends FeedTownshipEntity {
  const FeedTownshipModel({required super.id, required super.code});

  factory FeedTownshipModel.fromJson(Map<String, dynamic> json) {
    return FeedTownshipModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'code': code};
}

class FeedMediaModel extends FeedMediaEntity {
  const FeedMediaModel({
    super.id,
    super.url,
    super.label,
    super.isVideo,
    super.width,
    super.height,
    super.bytes,
    super.fileName,
    super.filePath,
  });

  factory FeedMediaModel.fromJson(Map<String, dynamic> json) {
    return FeedMediaModel(
      id: json['id'] as int?,
      url: json['url'] as String?,
      label: json['label'] as String?,
      isVideo: json['type'] == 'video',
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'type': isVideo ? 'video' : 'image',
    'url': url,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (label != null) 'label': label,
  };
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
      allowLike: json['like'] ?? json['allow_like'] ?? true,
      allowDislike: json['dislike'] ?? json['allow_dislike'] ?? true,
      allowComment: json['comment'] ?? json['allow_comment'] ?? true,
      allowReply: json['reply'] ?? json['allow_reply'] ?? true,
      allowShare: json['share'] ?? json['allow_share'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'like': allowLike,
    'dislike': allowDislike,
    'comment': allowComment,
    'reply': allowReply,
    'share': allowShare,
  };
}

class FeedPollOptionModel extends FeedPollOptionEntity {
  const FeedPollOptionModel({
    required super.index,
    required super.label,
    super.votes,
    super.percent,
  });

  factory FeedPollOptionModel.fromJson(Map<String, dynamic> json) {
    return FeedPollOptionModel(
      index: json['index'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'label': label,
    'votes': votes,
    'percent': percent,
  };
}

class FeedPollModel extends FeedPollEntity {
  const FeedPollModel({
    required super.options,
    super.totalVoters,
    super.isMultiple,
    super.image,
    super.myVotes,
    super.hasVoted,
  });

  factory FeedPollModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final List<FeedPollOptionEntity> options = [];
    for (var i = 0; i < rawOptions.length; i++) {
      final opt = rawOptions[i];
      if (opt is Map) {
        options.add(FeedPollOptionModel.fromJson(Map<String, dynamic>.from(opt)));
      } else if (opt is String) {
        options.add(FeedPollOptionModel(index: i + 1, label: opt));
      }
    }

    final image = json['image'] as Map<String, dynamic>?;
    final myVotes = (json['my_votes'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    final hasVoted = json['has_voted'] as bool? ?? myVotes.isNotEmpty;

    return FeedPollModel(
      options: options,
      totalVoters: (json['total_voters'] as num?)?.toInt() ?? 0,
      isMultiple: json['multiple'] == true || json['is_multiple'] == true,
      image: image == null ? null : FeedMediaModel.fromJson(image),
      myVotes: myVotes,
      hasVoted: hasVoted,
    );
  }

  Map<String, dynamic> toJson() => {
    'multiple': isMultiple,
    'total_voters': totalVoters,
    'has_voted': hasVoted,
    'my_votes': myVotes,
    'options': options.map((e) => (e as FeedPollOptionModel).toJson()).toList(),
    if (image != null) 'image': (image as FeedMediaModel).toJson(),
  };
}

class FeedLinkModel extends FeedLinkEntity {
  const FeedLinkModel({
    required super.url,
    required super.platform,
    super.channel,
    required super.title,
    super.description,
  });

  factory FeedLinkModel.fromJson(Map<String, dynamic> json) {
    final platform = json['platform'] as String? ?? json['source'] as String? ?? 'web';
    final channel = json['channel'] as String? ?? json['source_label'] as String?;
    return FeedLinkModel(
      url: json['url'] as String? ?? '',
      platform: platform,
      channel: channel,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'url': url,
    'channel': channel,
    'title': title,
    'description': description,
  };
}

class FeedPostModel extends FeedPostEntity {
  const FeedPostModel({
    required super.id,
    required super.type,
    required super.status,
    required super.author,
    super.township,
    super.text,
    super.label,
    super.project,
    super.media,
    super.poll,
    super.link,
    super.settings,
    required super.publishAt,
    super.submittedAt,
    super.likeCount,
    super.dislikeCount,
    super.myReaction,
    super.commentCount,
    super.latestComment,
    super.rejectReason,
    super.isPinned,
    super.isMine,
    super.fromAdminWeb,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    final poll = json['poll'] as Map<String, dynamic>?;
    final link = json['link'] as Map<String, dynamic>?;
    final township = json['township'] as Map<String, dynamic>?;
    final latestComment = json['latest_comment'] as Map<String, dynamic>?;

    final counts = json['counts'] as Map<String, dynamic>?;
    final likeCount = counts != null
        ? (counts['likes'] as num?)?.toInt() ?? 0
        : (json['like_count'] as num?)?.toInt() ?? 0;
    final dislikeCount = counts != null
        ? (counts['dislikes'] as num?)?.toInt() ?? 0
        : (json['dislike_count'] as num?)?.toInt() ?? 0;
    final commentCount = counts != null
        ? (counts['comments'] as num?)?.toInt() ?? 0
        : (json['comment_count'] as num?)?.toInt() ?? 0;

    final allowMap = json['allow'] as Map<String, dynamic>? ?? json['settings'] as Map<String, dynamic>?;
    final settings = allowMap != null
        ? FeedInteractionSettingsModel.fromJson(allowMap)
        : const FeedInteractionSettingsModel();

    final isPinned = json['is_pinned'] == true;
    final myReactionStr = json['my_reaction'] as String?;
    final myReaction = myReactionStr == 'like'
        ? FeedReaction.like
        : myReactionStr == 'dislike'
            ? FeedReaction.dislike
            : FeedReaction.none;

    // Semua waktu jadi jam dinding WIB (lihat DateHelper.parseServerTime). Draft dari layar moderator
    // tidak punya published_at → pakai updated_at (terakhir diubah).
    final submittedAt = DateHelper.parseServerTime(json['submitted_at'] as String?);
    final publishAt = DateHelper.parseServerTime(json['published_at'] as String? ?? json['publish_at'] as String?) ??
        DateHelper.parseServerTime(json['updated_at'] as String?) ??
        submittedAt ??
        AppTime.now();

    final statusStr = json['status'] as String?;
    final status = statusStr != null
        ? FeedPostStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => FeedPostStatus.published,
          )
        : FeedPostStatus.published;

    final isMine = json['is_mine'] == true || statusStr == 'review' || statusStr == 'rejected' || submittedAt != null;

    return FeedPostModel(
      id: json['id'] as int,
      type: FeedPostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedPostType.post,
      ),
      status: status,
      author: FeedAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? const {}),
      township: township != null ? FeedTownshipModel.fromJson(township) : null,
      text: json['text'] as String? ?? '',
      label: json['label'] as String?,
      project: json['project'] as String?,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((e) => FeedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      poll: poll == null ? null : FeedPollModel.fromJson(poll),
      link: link == null ? null : FeedLinkModel.fromJson(link),
      settings: settings,
      publishAt: publishAt,
      submittedAt: submittedAt,
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      myReaction: myReaction,
      commentCount: commentCount,
      latestComment: latestComment == null ? null : FeedCommentModel.fromJson(latestComment),
      rejectReason: json['reject_reason'] as String?,
      isPinned: isPinned,
      isMine: isMine,
      fromAdminWeb: json['source'] == 'admin',
    );
  }
}

class FeedPageModel extends FeedPageEntity {
  const FeedPageModel({
    super.pinned,
    required super.items,
    super.currentPage,
    super.perPage,
    super.total,
    super.hasMore,
  });

  factory FeedPageModel.fromJson(Map<String, dynamic> json) {
    final pinned = (json['pinned'] as List<dynamic>? ?? const [])
        .map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final items = (json['items'] as List<dynamic>? ?? json['data'] as List<dynamic>? ?? const [])
        .map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final currentPage = json['current_page'] as int? ?? 1;
    final perPage = json['per_page'] as int? ?? 10;
    final total = json['total'] as int? ?? items.length;
    final hasMore = json['has_more'] as bool? ?? (json['last_page'] != null ? currentPage < (json['last_page'] as int) : false);

    return FeedPageModel(
      pinned: pinned,
      items: items,
      currentPage: currentPage,
      perPage: perPage,
      total: total,
      hasMore: hasMore,
    );
  }
}
