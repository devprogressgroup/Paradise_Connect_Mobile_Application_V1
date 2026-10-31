import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

enum FeedPostType { post, poll, link }

/// `published` tayang di feed, `scheduled` tayang otomatis di [FeedPostEntity.publishAt],
/// `draft` disimpan moderator, `review`/`rejected` kiriman sales yang menunggu/ditolak moderator.
enum FeedPostStatus { published, scheduled, draft, review, rejected }

enum FeedReaction { none, like, dislike }

class FeedTownshipEntity extends Equatable {
  final int id;
  final String code;

  const FeedTownshipEntity({required this.id, required this.code});

  @override
  List<Object?> get props => [id, code];
}

class FeedMediaEntity extends Equatable {
  final int? id;
  final String? url;
  final String? label;
  final bool isVideo;
  final int? width;
  final int? height;

  /// Isi file yang baru dipilih dari galeri (belum ter-upload) — dipakai untuk preview lokal.
  final Uint8List? bytes;
  final String? fileName;
  final String? filePath;

  const FeedMediaEntity({
    this.id,
    this.url,
    this.label,
    this.isVideo = false,
    this.width,
    this.height,
    this.bytes,
    this.fileName,
    this.filePath,
  });

  @override
  List<Object?> get props => [id, url, label, isVideo, width, height, bytes, fileName, filePath];
}

/// Pengaturan interaksi per post yang diatur moderator. [allowReply] tidak berlaku kalau
/// [allowComment] mati.
class FeedInteractionSettings extends Equatable {
  final bool allowLike;
  final bool allowDislike;
  final bool allowComment;
  final bool allowReply;
  final bool allowShare;

  const FeedInteractionSettings({
    this.allowLike = true,
    this.allowDislike = true,
    this.allowComment = true,
    this.allowReply = true,
    this.allowShare = true,
  });

  FeedInteractionSettings copyWith({
    bool? allowLike,
    bool? allowDislike,
    bool? allowComment,
    bool? allowReply,
    bool? allowShare,
  }) {
    return FeedInteractionSettings(
      allowLike: allowLike ?? this.allowLike,
      allowDislike: allowDislike ?? this.allowDislike,
      allowComment: allowComment ?? this.allowComment,
      allowReply: allowReply ?? this.allowReply,
      allowShare: allowShare ?? this.allowShare,
    );
  }

  @override
  List<Object?> get props => [allowLike, allowDislike, allowComment, allowReply, allowShare];
}

class FeedPollOptionEntity extends Equatable {
  final int index;
  final String label;
  final int votes;
  final int percent;

  const FeedPollOptionEntity({
    required this.index,
    required this.label,
    this.votes = 0,
    this.percent = 0,
  });

  @override
  List<Object?> get props => [index, label, votes, percent];
}

class FeedPollEntity extends Equatable {
  final List<FeedPollOptionEntity> options;
  final int totalVoters;
  final bool isMultiple;
  final FeedMediaEntity? image;
  final List<int> myVotes;
  final bool hasVoted;

  const FeedPollEntity({
    required this.options,
    this.totalVoters = 0,
    this.isMultiple = false,
    this.image,
    this.myVotes = const [],
    this.hasVoted = false,
  });

  int percentOf(int optionIndex) {
    for (final opt in options) {
      if (opt.index == optionIndex) return opt.percent;
    }
    return 0;
  }

  @override
  List<Object?> get props => [options, totalVoters, isMultiple, image, myVotes, hasVoted];
}

class FeedLinkEntity extends Equatable {
  final String url;
  final String platform;
  final String? channel;
  final String title;
  final String? description;

  const FeedLinkEntity({
    required this.url,
    required this.platform,
    this.channel,
    required this.title,
    this.description,
  });

  String get source => platform;
  String? get sourceLabel => channel;
  bool get isYoutube => platform == 'youtube';

  @override
  List<Object?> get props => [url, platform, channel, title, description];
}

class FeedPostEntity extends Equatable {
  final int id;
  final FeedPostType type;
  final FeedPostStatus status;
  final FeedAuthorEntity author;
  final FeedTownshipEntity? township;

  /// Caption/pertanyaan. Bagian yang diapit `**` ditampilkan tebal.
  final String text;
  final String? label;
  final String? project;
  final List<FeedMediaEntity> media;
  final FeedPollEntity? poll;
  final FeedLinkEntity? link;
  final FeedInteractionSettings settings;

  /// Waktu tayang (published/scheduled), waktu dikirim (review/rejected), atau terakhir diubah (draft).
  final DateTime publishAt;
  final DateTime? submittedAt;

  /// Sudah termasuk reaksi user sendiri.
  final int likeCount;
  final int dislikeCount;
  final FeedReaction myReaction;
  final int commentCount;
  final FeedCommentEntity? latestComment;
  final String? rejectReason;
  final bool isPinned;
  final bool isMine;
  final bool fromAdminWeb;

  const FeedPostEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.author,
    this.township,
    this.text = '',
    this.label,
    this.project,
    this.media = const [],
    this.poll,
    this.link,
    this.settings = const FeedInteractionSettings(),
    required this.publishAt,
    this.submittedAt,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.myReaction = FeedReaction.none,
    this.commentCount = 0,
    this.latestComment,
    this.rejectReason,
    this.isPinned = false,
    this.isMine = false,
    this.fromAdminWeb = false,
  });

  String get plainText => type == FeedPostType.link ? (link?.title ?? '') : text.replaceAll('**', '');

  /// Untuk link YouTube tanpa upload manual, backend sudah mengisi [media] dengan thumbnail YouTube.
  FeedMediaEntity? get thumbnail => media.isNotEmpty ? media.first : poll?.image;

  FeedPostEntity copyWith({
    int? likeCount,
    int? dislikeCount,
    FeedReaction? myReaction,
    int? commentCount,
    FeedPollEntity? poll,
    bool? isPinned,
  }) {
    return FeedPostEntity(
      id: id,
      type: type,
      status: status,
      author: author,
      township: township,
      text: text,
      label: label,
      project: project,
      media: media,
      poll: poll ?? this.poll,
      link: link,
      settings: settings,
      publishAt: publishAt,
      submittedAt: submittedAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      myReaction: myReaction ?? this.myReaction,
      commentCount: commentCount ?? this.commentCount,
      latestComment: latestComment,
      rejectReason: rejectReason,
      isPinned: isPinned ?? this.isPinned,
      isMine: isMine,
      fromAdminWeb: fromAdminWeb,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    author,
    township,
    text,
    label,
    project,
    media,
    poll,
    link,
    settings,
    publishAt,
    submittedAt,
    likeCount,
    dislikeCount,
    myReaction,
    commentCount,
    latestComment,
    rejectReason,
    isPinned,
    isMine,
    fromAdminWeb,
  ];
}

/// Wrapper paginasi feed.
class FeedPageEntity extends Equatable {
  final List<FeedPostEntity> pinned;
  final List<FeedPostEntity> items;
  final int currentPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const FeedPageEntity({
    this.pinned = const [],
    required this.items,
    this.currentPage = 1,
    this.perPage = 10,
    this.total = 0,
    this.hasMore = false,
  });

  bool get hasNextPage => hasMore;
  int get lastPage => perPage > 0 ? ((total + perPage - 1) ~/ perPage) : 1;

  @override
  List<Object?> get props => [pinned, items, currentPage, perPage, total, hasMore];
}
