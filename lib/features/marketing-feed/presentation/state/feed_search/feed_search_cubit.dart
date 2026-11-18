import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/search_feed_posts_usecase.dart';

enum FeedSearchStatus { initial, loading, loaded, error }

class FeedSearchState {
  final FeedSearchStatus status;
  final String query;
  final List<FeedPostEntity> items;
  final String? errorMessage;

  const FeedSearchState({
    this.status = FeedSearchStatus.initial,
    this.query = '',
    this.items = const [],
    this.errorMessage,
  });
}

/// State halaman pencarian Marketing Feed.
class FeedSearchCubit extends Cubit<FeedSearchState> {
  final SearchFeedPostsUseCase searchFeedPostsUseCase;

  FeedSearchCubit({required this.searchFeedPostsUseCase})
    : super(const FeedSearchState());

  Future<void> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      emit(const FeedSearchState());
      return;
    }
    emit(FeedSearchState(status: FeedSearchStatus.loading, query: query));
    final result = await searchFeedPostsUseCase(q: query);
    if (isClosed) return;
    result.fold(
      (message) => emit(
        FeedSearchState(
          status: FeedSearchStatus.error,
          query: query,
          errorMessage: message,
        ),
      ),
      (page) => emit(
        FeedSearchState(
          status: FeedSearchStatus.loaded,
          query: query,
          items: page.items,
        ),
      ),
    );
  }
}
