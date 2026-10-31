import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_comment_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/personal_funnel_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/wall_of_fame_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_comment_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';

class CommentLikeResult {
  final bool liked;
  final int likeCount;

  const CommentLikeResult({required this.liked, required this.likeCount});
}

class PostReactionResult {
  final FeedReaction myReaction;
  final int likes;
  final int dislikes;

  const PostReactionResult({
    required this.myReaction,
    required this.likes,
    required this.dislikes,
  });
}

abstract class MarketingFeedRemoteDataSource {
  /// GET /api/marketing-feed?page=&per_page=
  Future<FeedPageModel> getFeedPosts({int page = 1, int perPage = 10});

  /// GET /api/marketing-feed/{id}
  Future<FeedPostModel> getFeedPost(int postId);

  /// GET /api/marketing-feed/wall-of-fame
  Future<List<WallOfFameLevelModel>> getWallOfFame();

  /// GET /api/marketing-feed/my-funnel
  Future<PersonalFunnelModel> getPersonalFunnel();

  /// POST /api/marketing-feed/{id}/reaction atau DELETE
  Future<PostReactionResult> reactToPost(int postId, FeedReaction reaction);

  /// POST /api/marketing-feed/{id}/vote {options: [index]}
  Future<FeedPollModel> votePoll(int postId, List<int> optionIndexes);

  /// GET /api/marketing-feed/{id}/comments?page=&per_page=
  Future<FeedCommentPageEntity> getComments(int postId, {int page = 1, int perPage = 10});

  /// POST /api/marketing-feed/{id}/comments {body, parent_id}
  Future<FeedCommentModel> addComment(int postId, String text, {int? parentId});

  /// POST /api/marketing-feed/comments/{commentId}/like atau DELETE
  Future<CommentLikeResult> toggleCommentLike(int commentId, {required bool currentlyLiked});

  /// POST /api/marketing-feed/submit (multipart)
  Future<FeedPostModel> shareMoment(ShareFeedMomentParams params);

  /// GET /api/marketing-feed/my-submissions?page=&per_page=
  Future<FeedPageModel> getMySubmissions({int page = 1, int perPage = 10});

  /// Moderator — GET /api/marketing-feed/moderator/posts: terjadwal & draft.
  Future<List<FeedPostModel>> getModeratorPosts();

  /// Moderator — POST /api/marketing-feed/moderator/posts (baru) atau /{id} (edit), multipart.
  Future<FeedPostModel> savePost(SaveFeedPostParams params);

  /// Moderator — POST /api/marketing-feed/moderator/posts/{id}/action {action: now|unsched|del}.
  Future<void> moderatorAction(int postId, String action);
}

/// File baru dari picker → MultipartFile. Di web filePath berupa blob URL dan dart:io tidak tersedia,
/// jadi pakai bytes. Null kalau media ini bukan file baru (media lama dari server).
Future<MultipartFile?> _multipartOf(FeedMediaEntity m, int index) async {
  if (!kIsWeb && m.filePath != null && m.filePath!.isNotEmpty) {
    final file = File(m.filePath!);
    if (await file.exists()) {
      final fileName = m.fileName ?? m.filePath!.split(Platform.pathSeparator).last;
      return MultipartFile.fromFile(m.filePath!, filename: fileName);
    }
  }
  if (m.bytes != null) {
    final ext = m.isVideo ? 'mp4' : 'jpg';
    return MultipartFile.fromBytes(m.bytes!, filename: m.fileName ?? 'media_$index.$ext');
  }
  return null;
}

class MarketingFeedRemoteDataSourceImpl implements MarketingFeedRemoteDataSource {
  final Dio dio;

  MarketingFeedRemoteDataSourceImpl(this.dio);

  @override
  Future<FeedPageModel> getFeedPosts({int page = 1, int perPage = 10}) async {
    try {
      final response = await dio.get(
        '/marketing-feed',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPageModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil feed.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil feed.');
    }
  }

  @override
  Future<FeedPostModel> getFeedPost(int postId) async {
    try {
      final response = await dio.get('/marketing-feed/$postId');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPostModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Post tidak ditemukan.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Post tidak ditemukan.');
    }
  }

  @override
  Future<List<WallOfFameLevelModel>> getWallOfFame() async {
    try {
      final response = await dio.get('/marketing-feed/wall-of-fame');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final dataMap = Map<String, dynamic>.from(body['data'] as Map);
        final items = (dataMap['items'] as List<dynamic>? ?? const []);
        return items
            .map((e) => WallOfFameLevelModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return const [];
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil Wall of Fame.');
    }
  }

  @override
  Future<PersonalFunnelModel> getPersonalFunnel() async {
    // TODO: endpoint /marketing-feed/my-funnel belum tersedia dari backend.
    // Sementara pakai dummy funnel (Progress Kamu) seperti diminta pada §7.
    return const PersonalFunnelModel(
      periodLabel: 'Bulan Berjalan',
      stages: [
        FunnelStageEntity(label: 'Leads', count: 12),
        FunnelStageEntity(label: 'Appt', count: 8),
        FunnelStageEntity(label: 'Visit', count: 5),
        FunnelStageEntity(label: 'Reserve', count: 2),
        FunnelStageEntity(label: 'SP', count: 1),
      ],
    );
  }

  @override
  Future<PostReactionResult> reactToPost(int postId, FeedReaction reaction) async {
    try {
      final Response response;
      if (reaction == FeedReaction.none) {
        response = await dio.delete('/marketing-feed/$postId/reaction');
      } else {
        response = await dio.post(
          '/marketing-feed/$postId/reaction',
          data: {'reaction': reaction.name},
        );
      }
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        final myReactionStr = d['my_reaction'] as String?;
        final myReaction = myReactionStr == 'like'
            ? FeedReaction.like
            : myReactionStr == 'dislike'
                ? FeedReaction.dislike
                : FeedReaction.none;
        return PostReactionResult(
          myReaction: myReaction,
          likes: (d['likes'] as num?)?.toInt() ?? 0,
          dislikes: (d['dislikes'] as num?)?.toInt() ?? 0,
        );
      }
      throw parseMarketingFeedException(body, 'Gagal menyimpan reaksi.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal menyimpan reaksi.');
    }
  }

  @override
  Future<FeedPollModel> votePoll(int postId, List<int> optionIndexes) async {
    try {
      final response = await dio.post(
        '/marketing-feed/$postId/vote',
        data: {'options': optionIndexes},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPollModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim suara poll.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim suara poll.');
    }
  }

  @override
  Future<FeedCommentPageEntity> getComments(int postId, {int page = 1, int perPage = 10}) async {
    try {
      final response = await dio.get(
        '/marketing-feed/$postId/comments',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedCommentModel.pageFromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil komentar.');
    }
  }

  @override
  Future<FeedCommentModel> addComment(int postId, String text, {int? parentId}) async {
    try {
      final response = await dio.post(
        '/marketing-feed/$postId/comments',
        data: {
          'body': text,
          if (parentId != null) 'parent_id': parentId,
        },
      );
      final body = response.data;
      if (body is Map && (body['status'] == true || response.statusCode == 201) && body['data'] != null) {
        return FeedCommentModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim komentar.');
    }
  }

  @override
  Future<CommentLikeResult> toggleCommentLike(int commentId, {required bool currentlyLiked}) async {
    try {
      final Response response;
      if (currentlyLiked) {
        response = await dio.delete('/marketing-feed/comments/$commentId/like');
      } else {
        response = await dio.post('/marketing-feed/comments/$commentId/like');
      }
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        return CommentLikeResult(
          liked: d['liked'] == true,
          likeCount: (d['like_count'] as num?)?.toInt() ?? 0,
        );
      }
      throw parseMarketingFeedException(body, 'Gagal menyukai komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal menyukai komentar.');
    }
  }

  @override
  Future<FeedPostModel> shareMoment(ShareFeedMomentParams params) async {
    try {
      final formData = FormData();
      if (params.text.isNotEmpty) {
        formData.fields.add(MapEntry('text', params.text));
      }
      if (params.townshipId != null) {
        formData.fields.add(MapEntry('township_id', params.townshipId.toString()));
      }

      for (var i = 0; i < params.media.length; i++) {
        final file = await _multipartOf(params.media[i], i);
        if (file != null) formData.files.add(MapEntry('media[]', file));
      }

      final response = await dio.post(
        '/marketing-feed/submit',
        data: formData,
        // Multipart dikirim langsung (tanpa proxy /px) — proxy menyatukan field ber-key sama
        // (`media[]`) dan membengkakkan body jadi base64.
        options: Options(
          extra: {'skipEncryption': true},
          sendTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: params.onProgress,
      );

      final body = response.data;
      if (body is Map && (body['status'] == true || response.statusCode == 201) && body['data'] != null) {
        return FeedPostModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim momen.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim momen.');
    }
  }

  @override
  Future<FeedPageModel> getMySubmissions({int page = 1, int perPage = 10}) async {
    try {
      final response = await dio.get(
        '/marketing-feed/my-submissions',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPageModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil kiriman saya.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil kiriman saya.');
    }
  }

  @override
  Future<List<FeedPostModel>> getModeratorPosts() async {
    try {
      final response = await dio.get('/marketing-feed/moderator/posts');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final items = (body['data'] as Map)['items'] as List<dynamic>? ?? const [];
        return items.map((e) => FeedPostModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil draft & konten terjadwal.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil draft & konten terjadwal.');
    }
  }

  @override
  Future<FeedPostModel> savePost(SaveFeedPostParams params) async {
    try {
      final formData = FormData();
      void field(String key, String value) => formData.fields.add(MapEntry(key, value));
      String flag(bool v) => v ? '1' : '0';

      field('type', params.type.name);
      field('action', params.asDraft ? 'draft' : 'submit');
      final scheduledAt = params.scheduledAt;
      field('mode', scheduledAt != null ? 'later' : 'now');
      // jam dinding WIB → server Asia/Jakarta
      if (scheduledAt != null) field('publish_at', DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt));
      if (params.townshipId != null) field('township_id', params.townshipId.toString());

      final s = params.settings;
      field('allow[like]', flag(s.allowLike));
      field('allow[dislike]', flag(s.allowDislike));
      field('allow[comment]', flag(s.allowComment));
      field('allow[reply]', flag(s.allowComment && s.allowReply));
      field('allow[share]', flag(s.allowShare));

      switch (params.type) {
        case FeedPostType.post:
          if (params.text.isNotEmpty) field('text', params.text);
        case FeedPostType.poll:
          field('question', params.text);
          for (final option in params.pollOptions) {
            field('options[]', option);
          }
          field('multiple', flag(params.pollMultiple));
        case FeedPostType.link:
          field('link[platform]', params.linkPlatform);
          field('link[url]', params.linkUrl);
          field('link[channel]', params.linkChannel);
          field('link[title]', params.linkTitle);
          field('link[desc]', params.linkDescription);
      }

      // Urutan carousel: "id:<media lama>" atau "new:<index media[]>". Media tanpa id & tanpa file
      // (mis. thumbnail YouTube otomatis dari backend) tidak dikirim.
      var newIndex = 0;
      for (var i = 0; i < params.media.length; i++) {
        final m = params.media[i];
        final file = await _multipartOf(m, i);
        if (file != null) {
          formData.files.add(MapEntry('media[]', file));
          field('media_order[]', 'new:${newIndex++}');
        } else if (m.id != null) {
          field('media_order[]', 'id:${m.id}');
        }
      }

      final postId = params.postId;
      final response = await dio.post(
        postId == null ? '/marketing-feed/moderator/posts' : '/marketing-feed/moderator/posts/$postId',
        data: formData,
        // Sama dengan shareMoment: multipart langsung tanpa proxy /px.
        options: Options(
          extra: {'skipEncryption': true},
          sendTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: params.onProgress,
      );

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPostModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      }
      throw parseMarketingFeedException(body, 'Gagal menyimpan konten.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal menyimpan konten.');
    }
  }

  @override
  Future<void> moderatorAction(int postId, String action) async {
    try {
      final response = await dio.post('/marketing-feed/moderator/posts/$postId/action', data: {'action': action});
      final body = response.data;
      if (body is Map && body['status'] == true) return;
      throw parseMarketingFeedException(body, 'Gagal memproses konten.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal memproses konten.');
    }
  }
}
