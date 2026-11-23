import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

enum FeedPublishedStatus { initial, loading, loaded, error }

class FeedPublishedState {
  final FeedPublishedStatus status;

  /// Semua kiriman yang sedang tayang (untuk user dengan izin ApproveReject).
  final List<FeedPostEntity> items;

  /// Kiriman yang sedang diproses (turunkan tayang / hapus).
  final int? busyId;
  final String? errorMessage;

  const FeedPublishedState({
    this.status = FeedPublishedStatus.initial,
    this.items = const [],
    this.busyId,
    this.errorMessage,
  });
}

/// Daftar kiriman tayang di tab Tayang untuk user dengan izin ApproveReject: turunkan tayang atau hapus.
class FeedPublishedCubit extends Cubit<FeedPublishedState> {
  final MarketingFeedRepository repository;

  FeedPublishedCubit({required this.repository}) : super(const FeedPublishedState());

  /// [silent] = pembaruan otomatis tanpa indikator loading.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(FeedPublishedState(status: FeedPublishedStatus.loading, items: state.items));
    }
    final result = await repository.getPublishedPosts();
    if (isClosed) return;
    result.fold(
      (message) => emit(
        FeedPublishedState(
          status: FeedPublishedStatus.error,
          items: state.items,
          errorMessage: message,
        ),
      ),
      (items) => emit(FeedPublishedState(status: FeedPublishedStatus.loaded, items: items)),
    );
  }

  /// 'unpub' = turunkan tayang (kembali ke draf), 'del' = hapus. Balikan: pesan error atau null kalau berhasil.
  Future<String?> act(int postId, String action) async {
    emit(FeedPublishedState(status: state.status, items: state.items, busyId: postId));
    final result = await repository.moderatorAction(postId, action);
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(FeedPublishedState(status: state.status, items: state.items));
        return message;
      },
      (_) {
        emit(
          FeedPublishedState(
            status: state.status,
            items: state.items.where((p) => p.id != postId).toList(),
          ),
        );
        return null;
      },
    );
  }
}
