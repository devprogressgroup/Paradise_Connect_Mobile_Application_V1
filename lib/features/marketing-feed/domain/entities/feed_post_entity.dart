import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_author_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

enum FeedPostType { post, poll, link }

/// `published` tayang di feed, `scheduled` tayang otomatis di [FeedPostEntity.publishAt],
/// `draft` disimpan moderator, `review`/`rejected` kiriman sales yang menunggu/ditolak moderator.
enum FeedPostStatus { published, scheduled, draft, review, rejected }

enum FeedReaction { none, like, dislike }

class FeedMediaEntity extends Equatable {
  final String? url;
  final String? label;
  final bool isVideo;

  /// Isi file yang baru dipilih dari galeri (belum ter-upload) — dipakai untuk preview lokal.
  final Uint8List? bytes;
  final String? fileName;

  const FeedMediaEntity({
    this.url,
    this.label,
    this.isVideo = false,
    this.bytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [url, label, isVideo, bytes, fileName];
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

class FeedPollEntity extends Equatable {
  final List<String> options;
  final List<int> votes;

  /// Jumlah orang yang sudah menjawab (bukan jumlah suara — poll multi-jawaban bisa >1 suara/orang).
  final int totalVoters;
  final bool isMultiple;
  final FeedMediaEntity? image;
  final List<int> myVotes;

  const FeedPollEntity({
    required this.options,
    required this.votes,
    this.totalVoters = 0,
    this.isMultiple = false,
    this.image,
    this.myVotes = const [],
  });

  bool get hasVoted => myVotes.isNotEmpty;

  int percentOf(int index) {
    if (totalVoters == 0 || index >= votes.length) return 0;
    return (votes[index] / totalVoters * 100).round();
  }

  @override
  List<Object?> get props => [options, votes, totalVoters, isMultiple, image, myVotes];
}

class FeedLinkEntity extends Equatable {
  final String url;

  /// `youtube` atau `web`.
  final String source;
  final String? sourceLabel;
  final String title;
  final String? description;

  const FeedLinkEntity({
    required this.url,
    required this.source,
    this.sourceLabel,
    required this.title,
    this.description,
  });

  bool get isYoutube => source == 'youtube';

  @override
  List<Object?> get props => [url, source, sourceLabel, title, description];
}

class FeedPostEntity extends Equatable {
  final int id;
  final FeedPostType type;
  final FeedPostStatus status;
  final FeedAuthorEntity author;

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

  /// Sudah termasuk reaksi user sendiri.
  final int likeCount;
  final int dislikeCount;
  final FeedReaction myReaction;
  final int commentCount;
  final FeedCommentEntity? latestComment;
  final String? rejectReason;
  final bool isMine;
  final bool fromAdminWeb;

  const FeedPostEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.author,
    this.text = '',
    this.label,
    this.project,
    this.media = const [],
    this.poll,
    this.link,
    this.settings = const FeedInteractionSettings(),
    required this.publishAt,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.myReaction = FeedReaction.none,
    this.commentCount = 0,
    this.latestComment,
    this.rejectReason,
    this.isMine = false,
    this.fromAdminWeb = false,
  });

  String get plainText => type == FeedPostType.link ? (link?.title ?? '') : text.replaceAll('**', '');

  FeedMediaEntity? get thumbnail => media.isNotEmpty ? media.first : poll?.image;

  FeedPostEntity copyWith({
    int? likeCount,
    int? dislikeCount,
    FeedReaction? myReaction,
    FeedPollEntity? poll,
  }) {
    return FeedPostEntity(
      id: id,
      type: type,
      status: status,
      author: author,
      text: text,
      label: label,
      project: project,
      media: media,
      poll: poll ?? this.poll,
      link: link,
      settings: settings,
      publishAt: publishAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      myReaction: myReaction ?? this.myReaction,
      commentCount: commentCount,
      latestComment: latestComment,
      rejectReason: rejectReason,
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
    text,
    label,
    project,
    media,
    poll,
    link,
    settings,
    publishAt,
    likeCount,
    dislikeCount,
    myReaction,
    commentCount,
    latestComment,
    rejectReason,
    isMine,
    fromAdminWeb,
  ];
}

/// Wrapper paginasi feed.
class FeedPageEntity extends Equatable {
  final List<FeedPostEntity> items;
  final int currentPage;
  final int lastPage;

  const FeedPageEntity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasNextPage => currentPage < lastPage;

  @override
  List<Object?> get props => [items, currentPage, lastPage];
}
