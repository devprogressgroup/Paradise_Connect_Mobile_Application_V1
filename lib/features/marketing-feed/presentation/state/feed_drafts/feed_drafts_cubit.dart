import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/delete_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_drafts_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/publish_feed_post_now_usecase.dart';
import 'feed_drafts_state.dart';

/// State halaman "Draft & Terjadwal" (moderator).
class FeedDraftsCubit extends Cubit<FeedDraftsState> {
  final GetFeedDraftsUseCase getFeedDraftsUseCase;
  final PublishFeedPostNowUseCase publishFeedPostNowUseCase;
  final DeleteFeedPostUseCase deleteFeedPostUseCase;

  FeedDraftsCubit({
    required this.getFeedDraftsUseCase,
    required this.publishFeedPostNowUseCase,
    required this.deleteFeedPostUseCase,
  }) : super(const FeedDraftsState());

  Future<void> fetch() async {
    emit(state.copyWith(status: FeedDraftsStatus.loading));
    final result = await getFeedDraftsUseCase();
    if (isClosed) return;
    result.fold(
      (message) => emit(state.copyWith(status: FeedDraftsStatus.error, errorMessage: message)),
      (data) => emit(FeedDraftsState(status: FeedDraftsStatus.loaded, items: data)),
    );
  }

  /// Balikan: pesan error, atau null kalau sukses.
  Future<String?> publishNow(int postId) async {
    final result = await publishFeedPostNowUseCase(postId);
    return result.fold((message) => message, (_) {
      _remove(postId);
      return null;
    });
  }

  /// Balikan: pesan error, atau null kalau sukses.
  Future<String?> delete(int postId) async {
    final result = await deleteFeedPostUseCase(postId);
    return result.fold((message) => message, (_) {
      _remove(postId);
      return null;
    });
  }

  void _remove(int postId) {
    if (isClosed) return;
    emit(state.copyWith(items: state.items.where((p) => p.id != postId).toList()));
  }
}
