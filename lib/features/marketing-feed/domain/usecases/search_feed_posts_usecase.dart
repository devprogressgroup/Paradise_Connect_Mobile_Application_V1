import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Cari kiriman yang boleh dilihat user (caption, judul/channel link, nama pembuat).
class SearchFeedPostsUseCase {
  final MarketingFeedRepository repository;

  SearchFeedPostsUseCase(this.repository);

  Future<Either<String, FeedPageEntity>> call({
    required String q,
    int page = 1,
    int perPage = 20,
  }) async {
    return await repository.searchFeedPosts(q: q, page: page, perPage: perPage);
  }
}
