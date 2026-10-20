import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';

class FeedCommentModel extends FeedCommentEntity {
  const FeedCommentModel({
    required super.id,
    required super.author,
    required super.text,
    required super.createdAt,
    super.likeCount,
    super.isLiked,
    super.replies,
  });

  factory FeedCommentModel.fromJson(Map<String, dynamic> json) {
    final replies = json['replies'] as List<dynamic>? ?? const [];
    return FeedCommentModel(
      id: json['id'] as int,
      author: FeedAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? const {}),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] == true,
      replies: replies.map((e) => FeedCommentModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
