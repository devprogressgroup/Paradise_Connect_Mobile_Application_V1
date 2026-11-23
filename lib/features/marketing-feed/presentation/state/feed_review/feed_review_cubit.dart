import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

enum FeedReviewStatus { initial, loading, loaded, error }

class FeedReviewState {
  final FeedReviewStatus status;

  /// Kiriman sales yang menunggu persetujuan.
  final List<FeedPostEntity> items;

  /// Kiriman yang sedang diproses (approve/reject), untuk menampilkan indikator di kartunya.
  final int? busyId;
  final String? errorMessage;

  const FeedReviewState({
    this.status = FeedReviewStatus.initial,
    this.items = const [],
    this.busyId,
    this.errorMessage,
  });
}

/// Antrean persetujuan kiriman sales (tab Persetujuan di Feeds). Hanya untuk user dengan izin ApproveReject.
class FeedReviewCubit extends Cubit<FeedReviewState> {
  final MarketingFeedRepository repository;

  FeedReviewCubit({required this.repository}) : super(const FeedReviewState());

  /// [silent] = pembaruan otomatis: tidak menampilkan indikator loading, daftar langsung diganti.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(FeedReviewState(status: FeedReviewStatus.loading, items: state.items));
    }
    final result = await repository.getReviewQueue();
    if (isClosed) return;
    result.fold(
      (message) => emit(
        FeedReviewState(
          status: FeedReviewStatus.error,
          items: state.items,
          errorMessage: message,
        ),
      ),
      (items) => emit(
        FeedReviewState(status: FeedReviewStatus.loaded, items: items),
      ),
    );
  }

  /// Setujui ('approve') atau tolak ('reject', alasan wajib). Balikan: pesan error, atau null kalau berhasil.
  /// Kiriman yang sudah diputuskan dikeluarkan dari antrean.
  Future<String?> decide(int postId, String decision, {String? reason, String? publishAt}) async {
    emit(
      FeedReviewState(
        status: state.status,
        items: state.items,
        busyId: postId,
      ),
    );
    final result = await repository.decideReview(
      postId,
      decision,
      reason: reason,
      publishAt: publishAt,
    );
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(FeedReviewState(status: state.status, items: state.items));
        return message;
      },
      (_) {
        emit(
          FeedReviewState(
            status: state.status,
            items: state.items.where((p) => p.id != postId).toList(),
          ),
        );
        return null;
      },
    );
  }
}
