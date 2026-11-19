import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/data/models/my_profile_model.dart';
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
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';
import 'package:progress_group/features/marketing-feed/data/models/fame_program_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/data/models/fame_manage_model.dart';

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
  Future<FeedCommentPageEntity> getComments(
    int postId, {
    int page = 1,
    int perPage = 10,
  });

  /// POST /api/marketing-feed/{id}/comments {body, parent_id}
  Future<FeedCommentModel> addComment(int postId, String text, {int? parentId});

  /// POST /api/marketing-feed/comments/{commentId}/like atau DELETE
  Future<CommentLikeResult> toggleCommentLike(
    int commentId, {
    required bool currentlyLiked,
  });

  /// POST /api/marketing-feed/submit (multipart)
  Future<FeedPostModel> shareMoment(ShareFeedMomentParams params);

  /// GET /api/marketing-feed/my-submissions?page=&per_page=
  Future<FeedPageModel> getMySubmissions({
    int page = 1,
    int perPage = 10,
    String? status,
  });

  /// GET /api/marketing-feed/me/profile — profil sales sendiri.
  Future<MyProfileEntity> getMyProfile({int? userId});

  /// GET /api/marketing-feed/search?q= — cari kiriman (caption, judul/channel link, nama pembuat).
  Future<FeedPageModel> searchFeedPosts({
    required String q,
    int page = 1,
    int perPage = 10,
  });

  /// Wall of Fame — like / dislike kartu: POST wall-of-fame/cards/{id}/reaction (null = batal).
  Future<PostReactionResult> reactFameCard(int cardId, FeedReaction reaction);

  /// Wall of Fame — GET wall-of-fame/cards/{id}/comments?page=&per_page=
  Future<FeedCommentPageEntity> getFameComments(
    int cardId, {
    int page = 1,
    int perPage = 10,
  });

  /// Wall of Fame — POST wall-of-fame/cards/{id}/comments {body, parent_id}
  Future<FeedCommentModel> addFameComment(
    int cardId,
    String text, {
    int? parentId,
  });

  /// Wall of Fame — POST / DELETE wall-of-fame/comments/{commentId}/like
  Future<CommentLikeResult> toggleFameCommentLike(
    int commentId, {
    required bool currentlyLiked,
  });

  /// Moderator — GET /api/marketing-feed/moderator/posts: terjadwal & draft.
  Future<List<FeedPostModel>> getModeratorPosts();

  /// Moderator — GET /api/marketing-feed/moderator/calendar?from=&to= (Kalender Jadwal): terjadwal & tayang.
  Future<List<FeedPostModel>> getModeratorCalendar({
    required DateTime from,
    required DateTime to,
  });

  /// Moderator — POST /api/marketing-feed/moderator/posts (baru) atau /{id} (edit), multipart.
  Future<FeedPostModel> savePost(SaveFeedPostParams params);

  /// Moderator — POST /api/marketing-feed/moderator/posts/{id}/action {action: now|unsched|del}.
  Future<void> moderatorAction(int postId, String action);

  /// Sematkan / lepas kiriman di profil sales (maks. 3). PUT atau DELETE /marketing-feed/me/posts/{id}/profile-pin.
  Future<void> setProfilePin(int postId, {required bool pinned});

  /// Wall of Fame baru: GET /marketing-feed/wall-of-fame/programs.
  Future<List<FameProgramEntity>> getFamePrograms();

  /// Kelola Wall of Fame: GET /marketing-feed/wall-of-fame/access (can_edit, can_create_program).
  Future<FameAccessEntity> getFameAccess();

  /// GET /marketing-feed/wall-of-fame/manage — program + kartu (admin). 403 kalau tidak punya izin.
  Future<List<FameManageProgramEntity>> getFameManage();

  /// GET /marketing-feed/wall-of-fame/candidates — sales yang bisa dipilih sebagai juara.
  Future<List<FameCandidateEntity>> getFameCandidates();

  /// POST /marketing-feed/wall-of-fame/cards (baru) atau POST .../cards/{id} (ubah), multipart.
  Future<FameAdminCardEntity> saveFameCard(
    FameCardParams params, {
    int? cardId,
  });

  /// POST /marketing-feed/wall-of-fame/cards/{id}/status {status, publish_at}.
  Future<FameAdminCardEntity> setFameCardStatus(
    int cardId,
    String status,
    DateTime? publishAt,
  );

  /// POST /marketing-feed/wall-of-fame/cards/{id}/media, multipart field `media`.
  Future<void> uploadFameCardMedia(int cardId, FeedMediaEntity media);

  /// DELETE /marketing-feed/wall-of-fame/cards/{id}/media.
  Future<void> deleteFameCardMedia(int cardId);

  /// DELETE /marketing-feed/wall-of-fame/cards/{id}.
  Future<void> deleteFameCard(int cardId);
}

/// File baru dari picker → MultipartFile. Di web filePath berupa blob URL dan dart:io tidak tersedia,
/// jadi pakai bytes. Null kalau media ini bukan file baru (media lama dari server).
Future<MultipartFile?> _multipartOf(FeedMediaEntity m, int index) async {
  if (!kIsWeb && m.filePath != null && m.filePath!.isNotEmpty) {
    final file = File(m.filePath!);
    if (await file.exists()) {
      final fileName =
          m.fileName ?? m.filePath!.split(Platform.pathSeparator).last;
      return MultipartFile.fromFile(m.filePath!, filename: fileName);
    }
  }
  if (m.bytes != null) {
    final ext = m.isVideo ? 'mp4' : 'jpg';
    return MultipartFile.fromBytes(
      m.bytes!,
      filename: m.fileName ?? 'media_$index.$ext',
    );
  }
  return null;
}

class MarketingFeedRemoteDataSourceImpl
    implements MarketingFeedRemoteDataSource {
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
        return FeedPageModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
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
        return FeedPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
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
            .map(
              (e) => WallOfFameLevelModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      return const [];
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil Wall of Fame.');
    }
  }

  @override
  Future<PersonalFunnelModel> getPersonalFunnel() async {
    try {
      final response = await dio.get('/marketing-feed/my-funnel');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        return PersonalFunnelModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      return const PersonalFunnelModel(periodLabel: '', stages: []);
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil Progress Kamu.');
    }
  }

  @override
  Future<PostReactionResult> reactToPost(
    int postId,
    FeedReaction reaction,
  ) async {
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
        return FeedPollModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim suara poll.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim suara poll.');
    }
  }

  @override
  Future<FeedCommentPageEntity> getComments(
    int postId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await dio.get(
        '/marketing-feed/$postId/comments',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedCommentModel.pageFromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil komentar.');
    }
  }

  @override
  Future<FeedCommentModel> addComment(
    int postId,
    String text, {
    int? parentId,
  }) async {
    try {
      final response = await dio.post(
        '/marketing-feed/$postId/comments',
        data: {'body': text, if (parentId != null) 'parent_id': parentId},
      );
      final body = response.data;
      if (body is Map &&
          (body['status'] == true || response.statusCode == 201) &&
          body['data'] != null) {
        return FeedCommentModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim komentar.');
    }
  }

  @override
  Future<CommentLikeResult> toggleCommentLike(
    int commentId, {
    required bool currentlyLiked,
  }) async {
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
        formData.fields.add(
          MapEntry('township_id', params.townshipId.toString()),
        );
      }

      // Status ditentukan server (permission SkipReview): submit = review atau langsung tayang, draft = draft.
      formData.fields.add(
        MapEntry('submit', params.asDraft ? 'draft' : 'review'),
      );
      final scheduledAt = params.scheduledAt;
      if (scheduledAt != null) {
        formData.fields.add(MapEntry('mode', 'later'));
        formData.fields.add(
          MapEntry(
            'publish_at',
            DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt),
          ),
        );
      }

      String flag(bool v) => v ? '1' : '0';
      final s = params.settings;
      formData.fields.addAll([
        MapEntry('allow[like]', flag(s.allowLike)),
        MapEntry('allow[dislike]', flag(s.allowDislike)),
        MapEntry('allow[comment]', flag(s.allowComment)),
        MapEntry('allow[reply]', flag(s.allowComment && s.allowReply)),
        MapEntry('allow[share]', flag(s.allowShare)),
      ]);

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
      if (body is Map &&
          (body['status'] == true || response.statusCode == 201) &&
          body['data'] != null) {
        return FeedPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim momen.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim momen.');
    }
  }

  @override
  Future<FeedPageModel> getMySubmissions({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      final response = await dio.get(
        '/marketing-feed/my-submissions',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPageModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil kiriman saya.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil kiriman saya.');
    }
  }

  @override
  Future<FeedPageModel> searchFeedPosts({
    required String q,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await dio.get(
        '/marketing-feed/search',
        queryParameters: {'q': q, 'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedPageModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mencari kiriman.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mencari kiriman.');
    }
  }

  @override
  Future<MyProfileEntity> getMyProfile({int? userId}) async {
    try {
      final response = await dio.get(
        userId == null
            ? '/marketing-feed/me/profile'
            : '/marketing-feed/users/$userId/profile',
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return MyProfileModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil profil.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil profil.');
    }
  }

  @override
  Future<List<FeedPostModel>> getModeratorPosts() async {
    try {
      final response = await dio.get('/marketing-feed/moderator/posts');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final items =
            (body['data'] as Map)['items'] as List<dynamic>? ?? const [];
        return items
            .map(
              (e) =>
                  FeedPostModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      throw parseMarketingFeedException(
        body,
        'Gagal mengambil draft & konten terjadwal.',
      );
    } catch (e) {
      throw parseMarketingFeedException(
        e,
        'Gagal mengambil draft & konten terjadwal.',
      );
    }
  }

  @override
  Future<PostReactionResult> reactFameCard(
    int cardId,
    FeedReaction reaction,
  ) async {
    try {
      final response = await dio.post(
        '/marketing-feed/wall-of-fame/cards/$cardId/reaction',
        data: {
          'reaction': reaction == FeedReaction.none ? null : reaction.name,
        },
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        final str = d['my_reaction'] as String?;
        return PostReactionResult(
          myReaction: str == 'like'
              ? FeedReaction.like
              : str == 'dislike'
              ? FeedReaction.dislike
              : FeedReaction.none,
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
  Future<FeedCommentPageEntity> getFameComments(
    int cardId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await dio.get(
        '/marketing-feed/wall-of-fame/cards/$cardId/comments',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return FeedCommentModel.pageFromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengambil komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil komentar.');
    }
  }

  @override
  Future<FeedCommentModel> addFameComment(
    int cardId,
    String text, {
    int? parentId,
  }) async {
    try {
      final response = await dio.post(
        '/marketing-feed/wall-of-fame/cards/$cardId/comments',
        data: {'body': text, if (parentId != null) 'parent_id': parentId},
      );
      final body = response.data;
      if (body is Map &&
          (body['status'] == true || response.statusCode == 201) &&
          body['data'] != null) {
        return FeedCommentModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal mengirim komentar.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengirim komentar.');
    }
  }

  @override
  Future<CommentLikeResult> toggleFameCommentLike(
    int commentId, {
    required bool currentlyLiked,
  }) async {
    try {
      final Response response;
      if (currentlyLiked) {
        response = await dio.delete(
          '/marketing-feed/wall-of-fame/comments/$commentId/like',
        );
      } else {
        response = await dio.post(
          '/marketing-feed/wall-of-fame/comments/$commentId/like',
        );
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
  Future<List<FeedPostModel>> getModeratorCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await dio.get(
        '/marketing-feed/moderator/calendar',
        queryParameters: {
          'from': DateFormat('yyyy-MM-dd').format(from),
          'to': DateFormat('yyyy-MM-dd').format(to),
        },
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final items =
            (body['data'] as Map)['items'] as List<dynamic>? ?? const [];
        return items
            .map(
              (e) =>
                  FeedPostModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      throw parseMarketingFeedException(
        body,
        'Gagal mengambil kalender jadwal.',
      );
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengambil kalender jadwal.');
    }
  }

  @override
  Future<FeedPostModel> savePost(SaveFeedPostParams params) async {
    try {
      final formData = FormData();
      void field(String key, String value) =>
          formData.fields.add(MapEntry(key, value));
      String flag(bool v) => v ? '1' : '0';

      field('type', params.type.name);
      field('action', params.asDraft ? 'draft' : 'submit');
      final scheduledAt = params.scheduledAt;
      field('mode', scheduledAt != null ? 'later' : 'now');
      // jam dinding WIB → server Asia/Jakarta
      if (scheduledAt != null)
        field('publish_at', DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt));
      if (params.townshipId != null)
        field('township_id', params.townshipId.toString());

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
        postId == null
            ? '/marketing-feed/moderator/posts'
            : '/marketing-feed/moderator/posts/$postId',
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
        return FeedPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, 'Gagal menyimpan konten.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal menyimpan konten.');
    }
  }

  @override
  Future<List<FameProgramEntity>> getFamePrograms() async {
    try {
      final response = await dio.get('/marketing-feed/wall-of-fame/programs');
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final items = (body['data'] as Map)['items'] as List? ?? const [];
        return parseFamePrograms(items);
      }
    } catch (_) {
      // Endpoint programs belum ada di backend (404). Lanjut ke fallback di bawah.
    }
    // Fallback: pakai /marketing-feed/wall-of-fame yang sudah tersedia, dipetakan jadi satu program.
    final levels = await getWallOfFame();
    return _programsFromLevels(levels);
  }

  /// Ambil `data` dari respons standar { status, message, data }; error dilempar sebagai MarketingFeedException.
  Future<dynamic> _fameGet(String path, String fallback) async {
    try {
      final response = await dio.get(path);
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        return body['data'];
      }
      throw parseMarketingFeedException(body, fallback);
    } catch (e) {
      throw parseMarketingFeedException(e, fallback);
    }
  }

  @override
  Future<FameAccessEntity> getFameAccess() async {
    final data = await _fameGet(
      '/marketing-feed/wall-of-fame/access',
      'Gagal mengambil hak akses Wall of Fame.',
    );
    return parseFameAccess(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<FameManageProgramEntity>> getFameManage() async {
    final data = await _fameGet(
      '/marketing-feed/wall-of-fame/manage',
      'Gagal mengambil Wall of Fame.',
    );
    final items = (data as Map)['items'] as List? ?? const [];
    return parseFameManage(items);
  }

  @override
  Future<List<FameCandidateEntity>> getFameCandidates() async {
    final data = await _fameGet(
      '/marketing-feed/wall-of-fame/candidates',
      'Gagal mengambil daftar sales.',
    );
    final items = (data as Map)['items'] as List? ?? const [];
    return parseFameCandidates(items);
  }

  /// Field form kartu. Semua nilai dikirim sebagai string; juara dikirim dengan nama indeks winners[i][field].
  Map<String, String> _fameFields(FameCardParams p) {
    final fields = <String, String>{
      'kategori': p.kategori,
      'status': p.status,
      'caption': p.caption ?? '',
    };
    if (p.programId != null) fields['program_id'] = '${p.programId}';
    if (p.namaProgram != null && p.namaProgram!.isNotEmpty) {
      fields['nama_program'] = p.namaProgram!;
      fields['periode_label'] = p.periodeLabel ?? '';
    }
    if (p.publishAt != null) {
      fields['publish_at'] = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(p.publishAt!);
    }
    for (var i = 0; i < p.winners.length; i++) {
      final w = p.winners[i];
      fields['winners[$i][user_id]'] = '${w.userId}';
      fields['winners[$i][ranking]'] = '${w.ranking}';
      fields['winners[$i][peringkat_label]'] = w.peringkatLabel ?? '';
      fields['winners[$i][posisi_label]'] = w.posisiLabel ?? '';
      fields['winners[$i][tim_label]'] = w.timLabel ?? '';
    }
    return fields;
  }

  @override
  Future<FameAdminCardEntity> saveFameCard(
    FameCardParams params, {
    int? cardId,
  }) async {
    const fallback = 'Gagal menyimpan Wall of Fame.';
    try {
      final formData = FormData.fromMap(_fameFields(params));
      final poster = params.poster;
      if (poster != null) {
        final file = await _multipartOf(poster, 0);
        if (file != null) formData.files.add(MapEntry('media', file));
      }
      final path = cardId == null
          ? '/marketing-feed/wall-of-fame/cards'
          : '/marketing-feed/wall-of-fame/cards/$cardId';
      final response = await dio.post(path, data: formData);
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        return parseFameAdminCard(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, fallback);
    } catch (e) {
      throw parseMarketingFeedException(e, fallback);
    }
  }

  @override
  Future<FameAdminCardEntity> setFameCardStatus(
    int cardId,
    String status,
    DateTime? publishAt,
  ) async {
    const fallback = 'Gagal mengubah status Wall of Fame.';
    try {
      final response = await dio.post(
        '/marketing-feed/wall-of-fame/cards/$cardId/status',
        data: {
          'status': status,
          if (publishAt != null)
            'publish_at': DateFormat('yyyy-MM-dd HH:mm').format(publishAt),
        },
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        return parseFameAdminCard(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw parseMarketingFeedException(body, fallback);
    } catch (e) {
      throw parseMarketingFeedException(e, fallback);
    }
  }

  @override
  Future<void> uploadFameCardMedia(int cardId, FeedMediaEntity media) async {
    const fallback = 'Gagal mengunggah poster Wall of Fame.';
    try {
      final file = await _multipartOf(media, 0);
      if (file == null) {
        throw const MarketingFeedException(
          message: 'File poster tidak bisa dibaca.',
        );
      }
      final formData = FormData();
      formData.files.add(MapEntry('media', file));
      final response = await dio.post(
        '/marketing-feed/wall-of-fame/cards/$cardId/media',
        data: formData,
      );
      final body = response.data;
      if (body is Map && body['status'] == true) return;
      throw parseMarketingFeedException(body, fallback);
    } catch (e) {
      throw parseMarketingFeedException(e, fallback);
    }
  }

  @override
  Future<void> deleteFameCardMedia(int cardId) => _fameDelete(
    '/marketing-feed/wall-of-fame/cards/$cardId/media',
    'Gagal menghapus poster Wall of Fame.',
  );

  @override
  Future<void> deleteFameCard(int cardId) => _fameDelete(
    '/marketing-feed/wall-of-fame/cards/$cardId',
    'Gagal menghapus kartu Wall of Fame.',
  );

  Future<void> _fameDelete(String path, String fallback) async {
    try {
      final response = await dio.delete(path);
      final body = response.data;
      if (body is Map && body['status'] == true) return;
      throw parseMarketingFeedException(body, fallback);
    } catch (e) {
      throw parseMarketingFeedException(e, fallback);
    }
  }

  /// Satu program "Wall of Fame" berisi kategori per level (TOP GM/SM/SPV/SE).
  /// Juara #1 = ranking 1, peringkat lain di [WallOfFameLevelEntity.runnersUp] = ranking 2 dst.
  List<FameProgramEntity> _programsFromLevels(
    List<WallOfFameLevelEntity> levels,
  ) {
    if (levels.isEmpty) return const [];

    FameEntryEntity toEntry(
      WallOfFameEntryEntity e,
      String level,
      int ranking,
      int id,
    ) {
      final media = e.media;
      // Data lama per orang: satu kartu = satu juara.
      return FameEntryEntity(
        id: e.id ?? id,
        programId: 0,
        programName: 'Wall of Fame',
        kategori: level,
        caption: e.highlight,
        mediaType: media == null || media.url == null
            ? null
            : (media.isVideo ? 'video' : 'image'),
        mediaUrl: media?.url,
        winners: [
          FameWinnerEntity(
            userId: 0,
            name: e.name,
            initials: e.initials ?? '',
            photoUrl: e.photoUrl,
            ranking: ranking,
            posisiLabel: e.info,
          ),
        ],
        juaraCount: 1,
        summary: '1 JUARA',
        topRank: ranking,
      );
    }

    final categories = <FameCategoryEntity>[];
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final entries = <FameEntryEntity>[
        toEntry(level.champion, level.level, 1, i * 100),
        for (var j = 0; j < level.runnersUp.length; j++)
          toEntry(level.runnersUp[j], level.level, j + 2, i * 100 + j + 1),
      ];
      categories.add(
        FameCategoryEntity(kategori: level.level, entries: entries),
      );
    }

    return [
      FameProgramEntity(
        id: 0,
        namaProgram: 'Wall of Fame',
        categories: categories,
      ),
    ];
  }

  @override
  Future<void> setProfilePin(int postId, {required bool pinned}) async {
    try {
      final path = '/marketing-feed/me/posts/$postId/profile-pin';
      final response = pinned ? await dio.put(path) : await dio.delete(path);
      final body = response.data;
      if (body is Map && body['status'] == true) return;
      throw parseMarketingFeedException(body, 'Gagal mengubah sematan profil.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal mengubah sematan profil.');
    }
  }

  Future<void> moderatorAction(int postId, String action) async {
    try {
      final response = await dio.post(
        '/marketing-feed/moderator/posts/$postId/action',
        data: {'action': action},
      );
      final body = response.data;
      if (body is Map && body['status'] == true) return;
      throw parseMarketingFeedException(body, 'Gagal memproses konten.');
    } catch (e) {
      throw parseMarketingFeedException(e, 'Gagal memproses konten.');
    }
  }
}
