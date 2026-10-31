import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

class FeedCommentModel extends FeedCommentEntity {
  const FeedCommentModel({
    required super.id,
    super.parentId,
    required super.author,
    required super.text,
    required super.createdAt,
    super.likeCount,
    super.isLiked,
    super.isMine,
    super.replies,
  });

  factory FeedCommentModel.fromJson(Map<String, dynamic> json) {
    final replies = (json['replies'] as List<dynamic>? ?? const [])
        .map((e) => FeedCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final text = json['body'] as String? ?? json['text'] as String? ?? '';
    final isLiked = json['liked_by_me'] == true || json['is_liked'] == true;

    return FeedCommentModel(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      author: FeedAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? const {}),
      text: text,
      createdAt: DateHelper.parseServerTime(json['created_at'] as String?) ?? AppTime.now(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      isLiked: isLiked,
      isMine: json['is_mine'] == true,
      replies: replies,
    );
  }

  static FeedCommentPageEntity pageFromJson(Map<String, dynamic> json) {
    return FeedCommentPageEntity(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => FeedCommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      hasMore: json['has_more'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'author': (author as FeedAuthorModel).toJson(),
    'body': text,
    'created_at': createdAt.toIso8601String(),
    'like_count': likeCount,
    'liked_by_me': isLiked,
    'is_mine': isMine,
    'replies': replies.map((e) => (e as FeedCommentModel).toJson()).toList(),
  };
}
