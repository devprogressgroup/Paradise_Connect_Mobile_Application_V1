import 'package:progress_group/features/marketing-feed/data/models/feed_comment_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/personal_funnel_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/wall_of_fame_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';

/// Kontrak data Marketing Feed. Endpoint di komentar tiap method masih USULAN — backend-nya belum
/// ada, jadi sementara yang dipasang di `main.dart` adalah `MarketingFeedDummyDataSource`.
abstract class MarketingFeedRemoteDataSource {
  /// GET /marketing-feed?page=&per_page= — kiriman sendiri yang review/ditolak di urutan teratas
  /// halaman 1, lalu post `published` terbaru.
  Future<FeedPageModel> getFeedPosts({int page = 1, int perPage = 10});

  /// GET /marketing-feed/{id}
  Future<FeedPostModel> getFeedPost(int postId);

  /// GET /marketing-feed/wall-of-fame
  Future<List<WallOfFameLevelModel>> getWallOfFame();

  /// GET /marketing-feed/my-funnel
  Future<PersonalFunnelModel> getPersonalFunnel();

  /// POST /marketing-feed/{id}/reaction {reaction: like|dislike|none}
  Future<FeedPostModel> reactToPost(int postId, FeedReaction reaction);

  /// POST /marketing-feed/{id}/vote {options: [index]}
  Future<FeedPostModel> votePoll(int postId, List<int> optionIndexes);

  /// GET /marketing-feed/{id}/comments
  Future<List<FeedCommentModel>> getComments(int postId);

  /// POST /marketing-feed/{id}/comments {text, parent_id} — balikan: seluruh komentar post.
  Future<List<FeedCommentModel>> addComment(int postId, String text, {int? parentId});

  /// POST /marketing-feed/{id}/comments/{commentId}/like — balikan: seluruh komentar post.
  Future<List<FeedCommentModel>> toggleCommentLike(int postId, int commentId);

  /// POST /marketing-feed/share (multipart) — status awal `review`.
  Future<FeedPostModel> shareMoment(ShareFeedMomentParams params);

  /// POST /marketing-feed/posts (baru) atau /marketing-feed/posts/{id} (edit), multipart.
  Future<FeedPostModel> savePost(SaveFeedPostParams params);

  /// GET /marketing-feed/drafts — status `scheduled` & `draft`.
  Future<List<FeedPostModel>> getDrafts();

  /// POST /marketing-feed/posts/{id}/publish
  Future<FeedPostModel> publishNow(int postId);

  /// DELETE /marketing-feed/posts/{id}
  Future<void> deletePost(int postId);
}
